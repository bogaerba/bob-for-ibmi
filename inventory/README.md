# IBM i Ansible Inventory

This directory contains inventory files that define the IBM i systems managed by this Ansible playbook.

## Directory Structure

```
inventory/
├── README.md                                    # This file
├── example-hosts.yml                            # Template with all configuration options
├── production/
│   ├── hosts.yml                                # Production IBM i hosts
│   └── group_vars/
│       └── ibmi_servers.yml                     # Production group variables
└── development/
    ├── hosts.yml                                # Development IBM i hosts
    └── group_vars/
        └── ibmi_servers.yml                     # Development group variables
```

## Quick Start

### 1. Choose Your Environment

Select the appropriate inventory for your environment:
- **Development**: `inventory/development/hosts.yml`
- **Production**: `inventory/production/hosts.yml`
- **Custom**: Copy `inventory/example-hosts.yml` and customize

### 2. Configure Your Hosts

Edit the hosts file for your environment:

```bash
# For development
vi inventory/development/hosts.yml

# For production
vi inventory/production/hosts.yml
```

Update the following required fields:
- `ansible_host`: IP address or hostname of your IBM i system
- `ansible_user`: SSH user with appropriate permissions
- `ansible_ssh_private_key_file`: Path to your SSH private key

### 3. Test Connectivity

Verify Ansible can connect to your IBM i systems:

```bash
# Test development environment
ansible -i inventory/development/hosts.yml ibmi_servers -m ping

# Test production environment
ansible -i inventory/production/hosts.yml ibmi_servers -m ping
```

Expected output:
```
ibmi-dev-01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Prerequisites

Before using these inventory files, ensure your IBM i systems meet these requirements:

### 1. SSH Access

SSH server must be running on IBM i:
```bash
# On IBM i, check SSH status
WRKACTJOB SBS(QSYSWRK) JOB(QP0ZSPWT)

# Start SSH if not running
STRTCPSVR SERVER(*SSHD)
```

### 2. Required Software

Install required packages on IBM i using yum:
```bash
# Connect to IBM i via SSH
ssh user@ibmi-host

# Install required packages
yum install python3 bash openssh
```

### 3. SSH Key Setup

Generate and copy SSH keys:
```bash
# On your Ansible control node
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_ibmi

# Copy public key to IBM i
ssh-copy-id -i ~/.ssh/id_rsa_ibmi.pub user@ibmi-host

# Test SSH connection
ssh -i ~/.ssh/id_rsa_ibmi user@ibmi-host
```

### 4. User Permissions

The Ansible user on IBM i needs:
- SSH access
- Authority to install packages (via yum)
- Authority to create directories and files
- Authority to run commands in PASE
- (Optional) Authority to create/modify database objects

## Configuration Guide

### Host Variables

Each host in the inventory requires these settings:

#### Required Variables

```yaml
ansible_host: 192.168.1.100                      # IP or hostname
ansible_user: ansible_user                       # SSH user
ansible_ssh_private_key_file: ~/.ssh/id_rsa_ibmi # SSH key path
ansible_shell_type: sh                           # Shell type (always 'sh' for IBM i)
ansible_shell_executable: /QOpenSys/pkgs/bin/bash # Bash path
ansible_python_interpreter: /QOpenSys/pkgs/bin/python3 # Python path
```

#### Optional Variables

```yaml
# Connection settings
ansible_port: 22
ansible_connection: ssh
ansible_ssh_common_args: '-o StrictHostKeyChecking=no'

# Performance settings
ansible_ssh_pipelining: true
ansible_ssh_transfer_method: scp

# Host metadata
ibmi_system_name: MYIBMI
ibmi_environment: production
ibmi_location: datacenter-1
```

### Group Variables

Group variables are defined in `group_vars/ibmi_servers.yml` and apply to all hosts in the group.

Key group variables include:
- Repository configuration (URL, branch, destination)
- Database settings (name, library, backup options)
- Build configuration (environment, optimization, debug)
- Package management settings
- Security and logging settings

See `example-hosts.yml` for complete documentation of all available variables.

## Usage Examples

### Running the Complete Playbook

```bash
# Development environment
ansible-playbook -i inventory/development/hosts.yml site.yml

# Production environment
ansible-playbook -i inventory/production/hosts.yml site.yml
```

### Limiting to Specific Hosts

```bash
# Run on a single host
ansible-playbook -i inventory/production/hosts.yml site.yml --limit ibmi-prod-01

# Run on multiple hosts
ansible-playbook -i inventory/production/hosts.yml site.yml --limit ibmi-prod-01,ibmi-prod-02
```

### Using Tags

```bash
# Run only prerequisites and package installation
ansible-playbook -i inventory/development/hosts.yml site.yml --tags "prerequisites,packages"

# Skip database setup
ansible-playbook -i inventory/development/hosts.yml site.yml --skip-tags "database"
```

### Check Mode (Dry Run)

```bash
# See what would change without making changes
ansible-playbook -i inventory/development/hosts.yml site.yml --check
```

### Verbose Output

```bash
# Increase verbosity for troubleshooting
ansible-playbook -i inventory/development/hosts.yml site.yml -v   # Basic
ansible-playbook -i inventory/development/hosts.yml site.yml -vv  # More detail
ansible-playbook -i inventory/development/hosts.yml site.yml -vvv # Debug level
```

## Advanced Configuration

### Multiple Environments

You can create additional environments by copying the structure:

```bash
# Create staging environment
mkdir -p inventory/staging/group_vars
cp inventory/development/hosts.yml inventory/staging/hosts.yml
cp inventory/development/group_vars/ibmi_servers.yml inventory/staging/group_vars/
```

### Host Groups

Organize hosts into logical groups for targeted deployments:

```yaml
all:
  children:
    ibmi_servers:
      children:
        ibmi_database_servers:
          hosts:
            ibmi-db-01:
            ibmi-db-02:
        ibmi_application_servers:
          hosts:
            ibmi-app-01:
            ibmi-app-02:
```

### Dynamic Inventory

For large environments, consider using dynamic inventory:
- AWS EC2 plugin
- Custom inventory scripts
- Ansible Tower/AWX

## Troubleshooting

### Connection Issues

**Problem**: `Failed to connect to the host via ssh`

**Solutions**:
1. Verify SSH service is running on IBM i
2. Check firewall rules allow SSH (port 22)
3. Verify SSH key permissions (should be 600)
4. Test manual SSH connection: `ssh -i ~/.ssh/id_rsa_ibmi user@host`

### Authentication Issues

**Problem**: `Permission denied (publickey)`

**Solutions**:
1. Verify public key is in `~/.ssh/authorized_keys` on IBM i
2. Check file permissions on IBM i:
   - `~/.ssh` should be 700
   - `~/.ssh/authorized_keys` should be 600
3. Verify correct private key path in inventory

### Python Issues

**Problem**: `/usr/bin/python: not found`

**Solutions**:
1. Install Python3: `yum install python3`
2. Verify `ansible_python_interpreter` points to correct path
3. Check Python installation: `which python3`

### Shell Issues

**Problem**: `Failed to execute command via shell`

**Solutions**:
1. Install bash: `yum install bash`
2. Verify `ansible_shell_executable` path is correct
3. Check bash installation: `which bash`

### Permission Issues

**Problem**: `Permission denied` when running tasks

**Solutions**:
1. Verify user has required authorities on IBM i
2. Check object ownership and permissions
3. Consider using `become` for privileged operations

## Security Best Practices

1. **SSH Keys**: Use separate SSH keys for different environments
2. **Key Permissions**: Ensure private keys have 600 permissions
3. **Vault**: Use Ansible Vault for sensitive variables
4. **Least Privilege**: Grant minimum required permissions to Ansible user
5. **Audit**: Enable audit logging in production environments
6. **Rotation**: Regularly rotate SSH keys and passwords

## Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [IBM i Ansible Collection](https://galaxy.ansible.com/ibm/power_ibmi)
- [IBM i Open Source](https://ibmi-oss-docs.readthedocs.io/)
- Project Documentation: `docs/ansible-design.md`

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review role-specific README files in `roles/*/README.md`
3. Consult the main project documentation
4. Check Ansible verbose output with `-vvv` flag

## Contributing

When adding new hosts or environments:
1. Follow the existing structure and naming conventions
2. Document any custom variables in group_vars
3. Test connectivity before committing changes
4. Update this README if adding new features or patterns