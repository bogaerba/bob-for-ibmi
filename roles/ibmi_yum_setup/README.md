# Role: ibmi_yum_setup

## Description

This role configures and verifies the YUM package manager on IBM i. It handles the installation of YUM via the bootstrap script if not already present, updates repository metadata, and ensures YUM is functional before proceeding with package installations.

## Requirements

- IBM i 7.3 or higher
- Internet connectivity for downloading bootstrap script
- Bash shell available at `/QOpenSys/pkgs/bin/bash`
- Sufficient disk space for YUM and package cache

## Role Variables

### Default Variables (defaults/main.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `yum_binary` | `/QOpenSys/pkgs/bin/yum` | Path to YUM binary |
| `bootstrap_url` | `https://public.dhe.ibm.com/software/ibmi/products/pase/rpms/bootstrap.sh` | URL for YUM bootstrap script |
| `bootstrap_timeout` | `1800` | Timeout for bootstrap installation (seconds) |
| `yum_optimize` | `true` | Whether to optimize YUM configuration |
| `yum_retry_count` | `3` | Number of retries for YUM operations |
| `yum_retry_delay` | `10` | Delay between retries (seconds) |

### Required Variables (from group_vars/all.yml)

| Variable | Description |
|----------|-------------|
| `target_home` | Home directory for temporary files |

## Tasks Performed

1. **Check YUM Installation**: Verifies if YUM is already installed
2. **Download Bootstrap Script**: Downloads the IBM YUM bootstrap script if needed
3. **Install YUM**: Executes bootstrap script to install YUM (if not present)
4. **Verify Installation**: Confirms YUM binary is installed and executable
5. **Update Repository Metadata**: Runs `yum makecache` to update package lists
6. **Check YUM Version**: Displays installed YUM version
7. **Test Functionality**: Verifies YUM can list installed packages
8. **Optimize Configuration**: Configures YUM for optimal performance

## Dependencies

- **ibmi_prerequisites**: Must run after prerequisites are verified

## Example Playbook

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_yum_setup
      tags: [yum, packages, setup]
```

## Tags

- `yum`: All YUM setup tasks
- `setup`: Initial setup tasks
- `bootstrap`: Bootstrap script download and execution
- `verify`: Verification tasks
- `update`: Repository metadata update
- `config`: Configuration tasks
- `cleanup`: Cleanup temporary files

## Error Handling

- **Retry Logic**: YUM operations retry up to 3 times with 10-second delays
- **Async Execution**: Bootstrap script runs asynchronously with 30-minute timeout
- **Validation**: Asserts YUM is functional before proceeding
- **Cleanup**: Removes bootstrap script after installation

## Performance Considerations

- First-time YUM installation can take 10-15 minutes
- Repository metadata updates may take several minutes
- Network connectivity is required for bootstrap and updates

## Troubleshooting

### YUM Installation Fails

- Check internet connectivity
- Verify proxy settings if behind a firewall
- Ensure sufficient disk space in `/QOpenSys/pkgs`
- Check bootstrap script URL is accessible

### Repository Metadata Update Fails

- Verify network connectivity to IBM repositories
- Check DNS resolution
- Review `/tmp/ansible-ibmi.log` for detailed errors

## Author

Generated for IBM Bob for IBM i project