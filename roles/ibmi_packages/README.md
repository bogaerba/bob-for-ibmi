# Role: ibmi_packages

## Description

This role installs all required open-source packages for IBM Bob on IBM i. It handles package installation via YUM, verifies successful installation, and logs package versions for troubleshooting.

## Requirements

- YUM package manager must be installed and functional
- Internet connectivity for downloading packages
- Sufficient disk space in `/QOpenSys/pkgs`

## Role Variables

### Default Variables (defaults/main.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `yum_binary` | `/QOpenSys/pkgs/bin/yum` | Path to YUM binary |
| `required_packages` | See below | List of packages to install |
| `package_retry_count` | `2` | Number of retries for failed installations |
| `package_retry_delay` | `5` | Delay between retries (seconds) |
| `update_cache` | `true` | Whether to update cache before installation |
| `log_installations` | `true` | Whether to log package installations |

### Required Packages

The following packages are installed by this role:

**Note:** Python 3.9 is installed separately in Phase 0 (Pre-Bootstrap) using raw SSH commands before any Ansible modules execute. This ensures a compatible Python interpreter is available for all subsequent Ansible operations.

1. **git** - Version control system for cloning repositories
2. **tn5250** - Terminal emulator for IBM i
3. **service-commander** - Service management tool
4. **mapepire-server** - Database connectivity server
5. **rsync** - File synchronization utility
6. **ibmichroot** - Chroot environment for IBM i
7. **nano** - Text editor
8. **tobi** - IBM i tools and utilities
9. **python39-itoolkit.ppc64** - Python interface to IBM i XMLSERVICE

### Required Variables (from group_vars/all.yml)

| Variable | Description |
|----------|-------------|
| `target_home` | Home directory for log files |

## Tasks Performed

1. **Update Package Cache**: Refreshes YUM repository metadata
2. **Check Installed Packages**: Verifies which packages are already installed
3. **Install Packages**: Installs each required package individually
4. **Verify Installation**: Confirms all packages are installed successfully
5. **Get Package Versions**: Records installed package versions
6. **Verify Critical Tools**: Specifically checks git and nano functionality
7. **Create Summary**: Generates installation summary
8. **Log Installation**: Records installation details to log file

## Dependencies

- **ibmi_prerequisites**: System prerequisites must be met
- **ibmi_yum_setup**: YUM must be installed and configured

## Example Playbook

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_packages
      tags: [packages, setup]
```

## Tags

- `packages`: All package installation tasks
- `update`: Cache update tasks
- `check`: Package check tasks
- `install`: Package installation tasks
- `verify`: Verification tasks
- `git`: Git-specific verification
- `nano`: Nano-specific verification
- `logging`: Logging tasks

## Error Handling

- **Individual Installation**: Packages are installed one at a time to isolate failures
- **Retry Logic**: Failed installations retry up to 2 times with 5-second delays
- **Verification**: All packages are verified after installation
- **Detailed Logging**: Installation results are logged for troubleshooting

## Idempotency

- Checks if packages are already installed before attempting installation
- Uses YUM's built-in idempotency (won't reinstall existing packages)
- Safe to run multiple times

## Performance Considerations

- Package installation time varies by package size and network speed
- Typical installation time: 5-15 minutes for all packages
- Cache updates may take 1-2 minutes

## Troubleshooting

### Package Installation Fails

- Check internet connectivity
- Verify YUM is functional: `yum list available`
- Check disk space: `df -h /QOpenSys/pkgs`
- Review package-specific errors in output

### Specific Package Not Found

- Update YUM cache: `yum makecache`
- Check package name spelling
- Verify package is available in IBM repositories

### Version Conflicts

- Check for existing package versions
- Consider removing old versions before installation
- Review YUM transaction logs

## Log Files

Package installations are logged to:
- `~/.ibmi-bob-packages.log` - Installation history with timestamps

## Author

Generated for IBM Bob for IBM i project