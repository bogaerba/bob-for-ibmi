# Role: ibmi_prerequisites

## Description

This role verifies system prerequisites and prepares the IBM i LPAR environment for IBM Bob setup. It performs essential checks to ensure the system meets minimum requirements before proceeding with package installation and configuration.

## Requirements

- IBM i 7.5 or higher (recommended)
- SSH access to the IBM i LPAR
- PASE environment available
- Bash shell installed at `/QOpenSys/pkgs/bin/bash`

## Role Variables

### Default Variables (defaults/main.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `required_ibmi_version` | `"7.5"` | Minimum required IBM i version |
| `required_directories` | `["{{ target_home }}"]` | List of directories to verify/create |
| `prerequisite_check_timeout` | `30` | Timeout for prerequisite checks (seconds) |
| `strict_version_check` | `false` | Whether to fail on version mismatch |

### Required Variables (from group_vars/all.yml)

| Variable | Description |
|----------|-------------|
| `target_user` | Target user for the setup |
| `target_home` | Home directory of the target user |

## Tasks Performed

1. **Verify SSH Connectivity**: Ensures Ansible can communicate with the IBM i system
2. **Gather System Facts**: Collects IBM i system information
3. **Check IBM i Version**: Verifies the system meets minimum version requirements
4. **Verify PASE Environment**: Ensures PASE is accessible and functional
5. **Check Bash Shell**: Verifies bash shell is installed and executable
6. **Verify User Home Directory**: Checks and creates user home directory if needed
7. **Create Required Directories**: Ensures all necessary directories exist
8. **Check User Authorities**: Displays user permissions and authorities
9. **Create Temporary Directory**: Sets up working directory for Ansible operations

## Dependencies

None. This is the first role in the playbook execution sequence.

## Example Playbook

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_prerequisites
      tags: [prerequisites, setup]
```

## Tags

- `prerequisites`: All prerequisite tasks
- `connectivity`: SSH connectivity checks
- `facts`: System fact gathering
- `version`: Version verification
- `pase`: PASE environment checks
- `bash`: Bash shell verification
- `directories`: Directory creation and verification
- `authorities`: User authority checks

## Error Handling

- **Fail Fast**: The role will fail immediately if critical prerequisites are not met
- **Clear Messages**: Provides detailed error messages with remediation steps
- **Idempotent**: Can be run multiple times without side effects

## Author

Generated for IBM Bob for IBM i project