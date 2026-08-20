<#
.SYNOPSIS
    Syncs active TechZone IBM i reservations into:
      - inventory/production/hosts.yml         (Ansible inventory)
      - %APPDATA%\IBM Bob\User\settings.json   (Bob for IBM i connections)
      - ~/.ssh/<hostname>.pem                  (SSH private keys)
      - ibmi_reservations.csv                  (reservation summary)

.DESCRIPTION
    Calls the TechZone MCP server (same as used by Bob internally) to list
    active reservations, fetches full details for each IBM i one, then:
      1. Writes the SSH private key to ~/.ssh/<hostname>.pem
      2. Upserts the host entry in inventory/production/hosts.yml
      3. Upserts the connection + connectionSettings in Bob's settings.json
      4. Upserts rows in ibmi_reservations.csv

.PARAMETER TechZoneToken
    Your TechZone API bearer token. If omitted, reads from techzone-key.txt
    in the workspace root, or from .bob/mcp.json.

.PARAMETER InventoryFile
    Path to the Ansible hosts.yml. Defaults to inventory/production/hosts.yml
    relative to the repo root (parent of the scripts/ folder).

.PARAMETER DryRun
    Print what would change without writing any files.

.EXAMPLE
    .\scripts\sync-techzone-ibmi.ps1
    .\scripts\sync-techzone-ibmi.ps1 -TechZoneToken "mytoken" -DryRun
#>

[CmdletBinding()]
param(
    [string]$TechZoneToken,
    [string]$InventoryFile,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference  = 'Stop'
$ProgressPreference     = 'SilentlyContinue'   # suppress Invoke-WebRequest progress noise

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
$ScriptDir        = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot         = Split-Path -Parent $ScriptDir
$DefaultInventory = Join-Path $RepoRoot 'inventory\production\hosts.yml'
$BobSettings      = Join-Path $env:APPDATA 'IBM Bob\User\settings.json'
$SshDir           = Join-Path $env:USERPROFILE '.ssh'
$KeyFile          = Join-Path $RepoRoot 'techzone-key.txt'
$BobMcpJson       = Join-Path $RepoRoot '.bob\mcp.json'
$CsvFile          = Join-Path $RepoRoot 'ibmi_reservations.csv'

if (-not $InventoryFile) { $InventoryFile = $DefaultInventory }

# ---------------------------------------------------------------------------
# Resolve token - from parameter, techzone-key.txt, or .bob/mcp.json
# ---------------------------------------------------------------------------
if (-not $TechZoneToken) {
    if (Test-Path $KeyFile) {
        $TechZoneToken = (Get-Content $KeyFile -Raw).Trim()
        Write-Host "  [token] Loaded from techzone-key.txt" -ForegroundColor DarkGray
    } elseif (Test-Path $BobMcpJson) {
        $mcpConfig = Get-Content $BobMcpJson -Raw | ConvertFrom-Json
        $TechZoneToken = $mcpConfig.mcpServers.techzone.headers.'TechZone-Token'
        if ($TechZoneToken) {
            Write-Host "  [token] Loaded from .bob/mcp.json" -ForegroundColor DarkGray
        }
    }
}
if (-not $TechZoneToken) {
    throw "No TechZoneToken found. Pass -TechZoneToken, or create techzone-key.txt in the repo root."
}

# ---------------------------------------------------------------------------
# Resolve MCP server URL from .bob/mcp.json
# ---------------------------------------------------------------------------
$McpUrl = $null
if (Test-Path $BobMcpJson) {
    $mcpConfig = Get-Content $BobMcpJson -Raw | ConvertFrom-Json
    $McpUrl = $mcpConfig.mcpServers.techzone.url
}
if (-not $McpUrl) {
    throw "Could not find TechZone MCP server URL in .bob/mcp.json"
}
Write-Host "  [mcp]   $McpUrl" -ForegroundColor DarkGray

# ---------------------------------------------------------------------------
# Helper: call a tool on the MCP server (streamable-http / JSON-RPC 2.0)
# ---------------------------------------------------------------------------
function Invoke-McpTool {
    param(
        [string]$ToolName,
        [hashtable]$Arguments
    )

    $headers = @{
        'Content-Type'   = 'application/json'
        'Accept'         = 'application/json, text/event-stream'
        'TechZone-Token' = $TechZoneToken
    }

    $iwrParams = @{
        Method          = 'POST'
        Uri             = $McpUrl
        Headers         = $headers
        UseBasicParsing = $true
        TimeoutSec      = 120
    }

    # 1. Initialize session
    $initBody = @{
        jsonrpc = '2.0'; id = 1; method = 'initialize'
        params  = @{
            protocolVersion = '2024-11-05'
            capabilities    = @{}
            clientInfo      = @{ name = 'sync-script'; version = '1.0' }
        }
    } | ConvertTo-Json -Depth 5 -Compress

    Invoke-WebRequest @iwrParams -Body $initBody -SessionVariable webSession | Out-Null

    # 2. Send initialized notification
    $notifyBody = '{"jsonrpc":"2.0","method":"notifications/initialized"}'
    Invoke-WebRequest @iwrParams -Body $notifyBody -WebSession $webSession | Out-Null

    # 3. Call the tool
    $callBody = @{
        jsonrpc = '2.0'; id = 2; method = 'tools/call'
        params  = @{
            name      = $ToolName
            arguments = $Arguments
        }
    } | ConvertTo-Json -Depth 10 -Compress

    $response = Invoke-WebRequest @iwrParams -Body $callBody -WebSession $webSession

    # The server may return plain JSON or SSE (data: {...} lines).
    # Try plain JSON first, then fall back to SSE line scanning.
    $raw = $response.Content.Trim()
    $parsed = $null

    # Try direct parse first
    try {
        $candidate = $raw | ConvertFrom-Json -ErrorAction Stop
        if ($candidate.PSObject.Properties['result'] -or $candidate.PSObject.Properties['error']) {
            $parsed = $candidate
        }
    } catch {}

    # Fall back: scan SSE lines for a data: {...} payload
    if ($null -eq $parsed) {
        foreach ($line in ($raw -split "`n")) {
            $line = $line.Trim()
            if ($line -match '^data:\s*(\{.+\})$') {
                $candidate = $Matches[1] | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($null -ne $candidate -and (
                    $candidate.PSObject.Properties['result'] -or
                    $candidate.PSObject.Properties['error'])) {
                    $parsed = $candidate
                    break
                }
            }
        }
    }

    if ($null -eq $parsed) {
        throw "Could not parse MCP response for '$ToolName'. Raw:`n$raw"
    }
    if ($parsed.PSObject.Properties['error'] -and $null -ne $parsed.error) {
        throw "MCP error for '$ToolName': $($parsed.error | ConvertTo-Json -Compress)"
    }

    # result.content[0].text is itself a JSON string — double-parse it.
    # PowerShell 5.1 ConvertFrom-Json rejects objects with duplicate keys that
    # differ only in case (e.g. "dataCenter" vs "datacenter" in TechZone output).
    # Fix: remove the camelCase variant whenever both appear side-by-side.
    $text = $parsed.result.content |
        Where-Object { $_.type -eq 'text' } |
        Select-Object -First 1 -ExpandProperty text

    $text = Remove-DuplicateJsonKeys $text
    return $text | ConvertFrom-Json
}

# Removes known duplicate case-variant keys that TechZone returns and that
# PowerShell 5.1 ConvertFrom-Json cannot handle.
# Strategy: for each known duplicate pair, remove the second occurrence.
function Remove-DuplicateJsonKeys {
    param([string]$Json)
    # "dataCenter":"<value>","datacenter":"<value>"  -> keep first, drop second
    $Json = [regex]::Replace($Json,
        '("dataCenter"\s*:\s*"[^"]*")\s*,\s*"datacenter"\s*:\s*"[^"]*"',
        '$1')
    # reverse order just in case
    $Json = [regex]::Replace($Json,
        '("datacenter"\s*:\s*"[^"]*")\s*,\s*"dataCenter"\s*:\s*"[^"]*"',
        '$1')
    return $Json
}

# ---------------------------------------------------------------------------
# 1. List active reservations via MCP
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==> Fetching active TechZone reservations via MCP..." -ForegroundColor Cyan

$allReservations = Invoke-McpTool -ToolName 'request-mcp-techzone-list-requests' -Arguments @{
    bearerToken = $TechZoneToken
    status      = 'Ready'
    limit       = 50
}

# Filter to IBM i only: name contains "IBM i" or environments contain ibmi os
$ibmiReservations = @($allReservations | Where-Object {
    $_.name -match 'IBM.?i\b' -or
    ($_.environments | Where-Object {
        $_.name -match 'IBM.?i\b' -or $_.name -match 'ibmi'
    })
})

if (@($ibmiReservations).Count -eq 0) {
    Write-Host "  No active IBM i reservations found." -ForegroundColor Yellow
    exit 0
}

Write-Host "  Found $(@($ibmiReservations).Count) active IBM i reservation(s)." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. Fetch full details (credentials) for each reservation
# ---------------------------------------------------------------------------
$parsed = foreach ($res in $ibmiReservations) {
    Write-Host ""
    Write-Host "  --> $($res.name)  [$($res.id)]" -ForegroundColor White

    $detail = Invoke-McpTool -ToolName 'request-mcp-techzone-get-request' -Arguments @{
        bearerToken = $TechZoneToken
        requestId   = $res.id
    }

    $env = $detail.environments | Where-Object { $_.status -eq 'Ready' } | Select-Object -First 1
    if (-not $env) { Write-Warning "    No Ready environment - skipping."; continue }

    $out = $env.output

    $hostname   = ($out | Where-Object name -eq 'vm1_hostname').value
    $publicIp   = ($out | Where-Object name -eq 'vm1_iface1_public_ip').value
    $username   = ($out | Where-Object name -eq 'user_name').value
    $password   = ($out | Where-Object name -eq 'user_password').value
    $privateKey = ($out | Where-Object name -eq 'ssh_private_key').value
    $sshPort    = ($out | Where-Object name -eq 'ssh_port').value
    if (-not $sshPort) { $sshPort = 22 }

    $geo = $detail.meta.inputs.region
    if (-not $geo) { $geo = $detail.environments[0].placement.geo }
    if (-not $geo) { $geo = 'unknown' }

    if (-not $hostname -or -not $publicIp -or -not $username) {
        Write-Warning "    Missing required output fields (hostname/ip/user) - skipping."
        continue
    }

    Write-Host "    hostname  : $hostname"   -ForegroundColor DarkGray
    Write-Host "    public IP : $publicIp"   -ForegroundColor DarkGray
    Write-Host "    username  : $username"   -ForegroundColor DarkGray
    Write-Host "    region    : $geo"        -ForegroundColor DarkGray

    # Capture schedule and environment title for the CSV while $detail is in scope
    $scheduleStr = ''
    if ($detail.PSObject.Properties['schedule'] -and $detail.schedule) {
        $s = $detail.schedule
        $schedStart  = if ($s.PSObject.Properties['start'] -and $s.start) { $s.start -replace 'T', ' ' -replace '\.\d+Z$', ' UTC' } else { '' }
        $schedEnd    = if ($s.PSObject.Properties['end']   -and $s.end)   { $s.end   -replace 'T', ' ' -replace '\.\d+Z$', ' UTC' } else { '' }
        $scheduleStr = "$schedStart-$schedEnd"
    }
    $envTitle = $res.name
    if ($env.PSObject.Properties['title'] -and $env.title) { $envTitle = $env.title }

    # Collect shared IBMid from access.maintain.users[1] (index 0 is the owner)
    $sharedWith = ''
    if ($detail.PSObject.Properties['access'] -and $detail.access -and
        $detail.access.PSObject.Properties['maintain'] -and $detail.access.maintain -and
        $detail.access.maintain.PSObject.Properties['users'] -and $detail.access.maintain.users -and
        @($detail.access.maintain.users).Count -gt 1) {
        $sharedWith = @($detail.access.maintain.users)[1]
    }

    [PSCustomObject]@{
        ReservationId = $res.id
        Name          = $res.name
        Hostname      = $hostname
        PublicIp      = $publicIp
        Username      = $username
        Password      = $password
        PrivateKey    = $privateKey
        SshPort       = [int]$sshPort
        Geo           = $geo
        Schedule      = $scheduleStr
        EnvTitle      = $envTitle
        SharedWith    = $sharedWith
    }
}

if (-not $parsed -or @($parsed).Count -eq 0) {
    Write-Host "  Nothing to sync after parsing reservation details." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------------------------
# 3. Write SSH private keys to ~/.ssh/<hostname>.pem
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==> Writing SSH private keys to $SshDir ..." -ForegroundColor Cyan

if (-not (Test-Path $SshDir)) {
    if (-not $DryRun) { New-Item -ItemType Directory -Path $SshDir | Out-Null }
    Write-Host "  Created $SshDir"
}

foreach ($r in $parsed) {
    $pemPath = Join-Path $SshDir "$($r.Hostname).pem"
    if ($r.PrivateKey) {
        Write-Host "  Writing $pemPath"
        if (-not $DryRun) {
            Set-Content -Path $pemPath -Value $r.PrivateKey -Encoding UTF8 -NoNewline
        }
    } else {
        Write-Warning "  No private key returned for $($r.Hostname) - skipping .pem"
    }
}

# ---------------------------------------------------------------------------
# 4. Update inventory/production/hosts.yml
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==> Updating Ansible inventory: $InventoryFile ..." -ForegroundColor Cyan

if (-not (Test-Path $InventoryFile)) { throw "Inventory file not found: $InventoryFile" }

$yaml = Get-Content $InventoryFile -Raw

foreach ($r in $parsed) {
    $pemRef = "~/.ssh/$($r.Hostname).pem"
    $hostPattern = [regex]::Escape("$($r.Hostname):")

    if ($yaml -match "(?m)^\s+$hostPattern") {
        Write-Host "  Updating existing entry: $($r.Hostname)"
        if (-not $DryRun) {
            # Update ansible_host line that follows the hostname block
            $yaml = $yaml -replace "(?ms)(^\s+$hostPattern\r?\n\s+ansible_host:)\s+[\d\.]+", "`${1} $($r.PublicIp)"
        }
    } else {
        Write-Host "  Adding new entry: $($r.Hostname)"
        $lines = @(
            ""
            ""
            "        # TechZone Reservation - $($r.Name) ($($r.Geo))"
            "        $($r.Hostname):"
            "          ansible_host: $($r.PublicIp)"
            "          ansible_user: $($r.Username)"
            "          ansible_ssh_private_key_file: $pemRef"
            "          ansible_port: $($r.SshPort)"
            ""
            "          # IBM i specific connection settings"
            "          ansible_shell_type: sh"
            "          ansible_shell_executable: /QOpenSys/pkgs/bin/bash"
            ""
            "          # Python interpreter - Two-Phase Bootstrap Approach"
            "          ansible_python_interpreter: /QOpenSys/pkgs/bin/python3"
            ""
            "          # Host-specific variables"
            "          ibmi_system_name: $($r.Hostname)"
            "          ibmi_environment: techzone"
            "          techzone_region: $($r.Geo)"
        )
        $block = $lines -join "`n"
        if (-not $DryRun) {
            $yaml = $yaml.TrimEnd([char]"`r", [char]"`n") + $block + "`n"
        }
    }
}

if (-not $DryRun) {
    Set-Content -Path $InventoryFile -Value $yaml -Encoding UTF8 -NoNewline
    Write-Host "  Saved $InventoryFile" -ForegroundColor Green
} else {
    Write-Host "  [DryRun] Would write $InventoryFile" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 5. Update Bob for IBM i settings.json
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==> Updating Bob settings: $BobSettings ..." -ForegroundColor Cyan

if (-not (Test-Path $BobSettings)) { throw "Bob settings not found: $BobSettings" }

$bobJson = Get-Content $BobSettings -Raw | ConvertFrom-Json

foreach ($r in $parsed) {
    $pemRef = "~/.ssh/$($r.Hostname).pem"

    # --- connections ---
    $existing = $bobJson.'code-for-ibmi.connections' | Where-Object { $_.name -eq $r.Hostname }
    if ($existing) {
        Write-Host "  Updating Bob connection: $($r.Hostname)"
        $existing.host           = $r.PublicIp
        $existing.port           = $r.SshPort
        $existing.username       = $r.Username
        $existing.privateKeyPath = $pemRef
    } else {
        Write-Host "  Adding Bob connection: $($r.Hostname)"
        $newConn = [PSCustomObject]@{
            name           = $r.Hostname
            host           = $r.PublicIp
            port           = $r.SshPort
            username       = $r.Username
            privateKeyPath = $pemRef
            passphrase     = ''
            enableMfa      = $false
            useSshAgent    = $false
        }
        $bobJson.'code-for-ibmi.connections' = @($bobJson.'code-for-ibmi.connections') + $newConn
    }

    # --- connectionSettings ---
    $existingSettings = $bobJson.'code-for-ibmi.connectionSettings' | Where-Object { $_.name -eq $r.Hostname }
    if (-not $existingSettings) {
        Write-Host "  Adding Bob connectionSettings: $($r.Hostname)"
        $newSettings = [PSCustomObject]@{
            name                           = $r.Hostname
            host                           = ''
            objectFilters                  = @()
            libraryList                    = @('QGPL', 'QTEMP')
            autoClearTempData              = $false
            customVariables                = @()
            connectionProfiles             = @()
            ifsShortcuts                   = @("/home/$($r.Username)")
            autoSortIFSShortcuts           = $false
            homeDirectory                  = "/home/$($r.Username)"
            tempLibrary                    = 'ILEDITOR'
            tempDir                        = '~/.vscode/tmp'
            currentLibrary                 = 'QGPL'
            sourceFileCCSID                = '*FILE'
            autoConvertIFSccsid            = $false
            hideCompileErrors              = @()
            enableSourceDates              = $true
            sourceDateGutter               = $false
            quickConnect                   = $true
            readOnlyMode                   = $false
            showHiddenFiles                = $true
            defaultDeploymentMethod        = ''
            debugPort                      = '8005'
            debugSepPort                   = '8008'
            debugUpdateProductionFiles     = $false
            debugEnableDebugTracing        = $false
            debugIgnoreCertificateErrors   = $false
            secureSQL                      = $false
            keepActionSpooledFiles         = $false
            autoUpdateDirectoryPermissions = 'ask'
            mapepireJavaVersion            = 'default'
            mapepireUseServer              = $false
            mapepireServerPort             = 8076
            mapepireAllowSelfCert          = $false
            ccsidConversionEnabled         = $false
            ccsidConvertFrom               = ''
            ccsidConvertTo                 = ''
        }
        $bobJson.'code-for-ibmi.connectionSettings' = @($bobJson.'code-for-ibmi.connectionSettings') + $newSettings
    } else {
        Write-Host "  connectionSettings already present for: $($r.Hostname)"
    }
}

if (-not $DryRun) {
    $bobJson | ConvertTo-Json -Depth 20 | Set-Content -Path $BobSettings -Encoding UTF8
    Write-Host "  Saved $BobSettings" -ForegroundColor Green
} else {
    Write-Host "  [DryRun] Would write $BobSettings" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 6. Update ibmi_reservations.csv
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==> Updating CSV: $CsvFile ..." -ForegroundColor Cyan

$csvHeader = 'Name,Status,Environment,Hostname,Public IP,SSH Port,Username,Password,TechZone URL,Schedule,Region,Request ID,Shared With'

# Helper: RFC-4180 CSV field escaping
function EscapeCsvField([string]$v) {
    if ($v -match '[",\r\n]') { return '"' + $v.Replace('"', '""') + '"' }
    return $v
}

# Load existing rows keyed by Request ID so we preserve rows from past runs
$existingRows = [ordered]@{}
if (Test-Path $CsvFile) {
    $csvLines = Get-Content $CsvFile
    foreach ($line in $csvLines) {
        # Skip the header line
        if ($line -match '^(?:[\uFEFF]?)Name,') { continue }
        # The Request ID is the last field (24-char hex, never quoted)
        if ($line -match ',([a-f0-9]{24})\s*$') {
            $existingRows[$Matches[1]] = $line
        }
    }
}

foreach ($r in $parsed) {
    $row = (EscapeCsvField $r.Name)      + ',' +
           'Ready'                        + ',' +
           (EscapeCsvField $r.EnvTitle)  + ',' +
           (EscapeCsvField $r.Hostname)  + ',' +
           (EscapeCsvField $r.PublicIp)  + ',' +
           $r.SshPort                    + ',' +
           (EscapeCsvField $r.Username)  + ',' +
           (EscapeCsvField $r.Password)  + ',' +
           "https://techzone.ibm.com/my/requests/$($r.ReservationId)" + ',' +
           (EscapeCsvField $r.Schedule)  + ',' +
           (EscapeCsvField $r.Geo)       + ',' +
           $r.ReservationId                                                 + ',' +
           (EscapeCsvField $r.SharedWith)

    $existingRows[$r.ReservationId] = $row
    Write-Host "  Upserted: $($r.Hostname)  [$($r.ReservationId)]" -ForegroundColor DarkGray
}

if (-not $DryRun) {
    $csvContent = $csvHeader
    foreach ($row in $existingRows.Values) { $csvContent += "`n" + $row }
    Set-Content -Path $CsvFile -Value $csvContent -Encoding UTF8 -NoNewline
    Write-Host "  Saved $CsvFile" -ForegroundColor Green
} else {
    Write-Host "  [DryRun] Would write $CsvFile" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==> Done! Synced $(@($parsed).Count) IBM i reservation(s):" -ForegroundColor Green
$parsed | Format-Table -AutoSize -Property ReservationId, Hostname, PublicIp, Username, Geo
