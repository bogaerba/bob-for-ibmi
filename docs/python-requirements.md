# Python Requirements for IBM i Ansible Playbooks

## Overview

This document outlines the Python version requirements and configuration for running Ansible playbooks on IBM i systems.

## Python Version Requirements

### Minimum Requirements
- **Python 3.7+** - Required for full Ansible compatibility
- **Python 3.9+** - Recommended for best compatibility and performance

### Known Issues
- **Python 3.6 and earlier** - Not supported due to missing language features (e.g., `from __future__ import annotations`)
- These older versions will cause `SyntaxError: future feature annotations is not defined`

## Configuration

### Automatic Python Discovery (Recommended)

The playbooks are configured to use `auto_silent` for Python interpreter discovery. This allows Ansible to automatically find the best available Python version on your IBM i system.

**Configuration locations:**
- `ansible.cfg` - Global setting: `interpreter_python = auto_silent`
- `inventory/*/hosts.yml` - Per-host setting: `ansible_python_interpreter: auto_silent`
- `group_vars/all.yml` - Group-level setting: `ansible_python_interpreter: auto_silent`

### Manual Python Path Configuration

If automatic discovery fails or you need to specify a particular Python version, you can set the interpreter path explicitly:

```yaml
# In inventory files or group_vars
ansible_python_interpreter: /QOpenSys/pkgs/bin/python3.9
```

## Common Python Paths on IBM i

Python installations on IBM i are typically located in:
- `/QOpenSys/pkgs/bin/python3.9`
- `/QOpenSys/pkgs/bin/python3.11`
- `/QOpenSys/pkgs/bin/python3` (symlink to default version)

## Checking Python Version

### On IBM i System

To check which Python versions are available on your IBM i system:

```bash
ssh user@ibmi-host "ls -la /QOpenSys/pkgs/bin/python*"
```

To check the version of a specific Python installation:

```bash
ssh user@ibmi-host "/QOpenSys/pkgs/bin/python3 --version"
```

### From Ansible

To verify which Python Ansible is using:

```bash
ansible ibmi-servers -m setup -a "filter=ansible_python_version"
```

## Installing/Upgrading Python on IBM i

If you need to install or upgrade Python on your IBM i system:

```bash
# Connect to IBM i
ssh user@ibmi-host

# Update yum repositories
yum update

# Install Python 3.9 (or newer)
yum install python39

# Verify installation
/QOpenSys/pkgs/bin/python3.9 --version
```

## Troubleshooting

### Error: "SyntaxError: future feature annotations is not defined"

**Cause:** The IBM i system is using Python 3.6 or earlier.

**Solution:**
1. Upgrade Python on the IBM i system to version 3.9 or newer
2. Ensure `ansible_python_interpreter: auto_silent` is set in your configuration
3. If auto_silent doesn't work, explicitly set the path to a newer Python version

### Error: "No python interpreters found"

**Cause:** Ansible cannot find a compatible Python installation.

**Solution:**
1. Install Python 3.9+ on the IBM i system using yum
2. Verify the installation path
3. Explicitly set `ansible_python_interpreter` to the correct path

### Verifying the Fix

After updating the configuration:

1. Run a simple Ansible command to test connectivity:
   ```bash
   ansible ibmi-servers -m ping
   ```

2. Check which Python version is being used:
   ```bash
   ansible ibmi-servers -m setup -a "filter=ansible_python*"
   ```

3. Run your playbook:
   ```bash
   ansible-playbook site.yml
   ```

## Best Practices

1. **Use auto_silent**: Let Ansible automatically discover the best Python version
2. **Keep Python updated**: Regularly update Python on IBM i systems to get security patches and new features
3. **Document custom paths**: If you must use a specific Python path, document it in your inventory
4. **Test after changes**: Always test playbooks after modifying Python interpreter settings

## References

- [Ansible Python Interpreter Discovery](https://docs.ansible.com/ansible/latest/reference_appendices/interpreter_discovery.html)
- [IBM i Open Source Python](https://ibmi-oss-docs.readthedocs.io/en/latest/python/README.html)
- [Python 3.7 Release Notes](https://docs.python.org/3/whatsnew/3.7.html)

---

*Last updated: 2026-03-03*
*Made with Bob*