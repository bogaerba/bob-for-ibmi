# IBM i LPAR Setup for IBM Bob

Comprehensive Ansible playbook to prepare IBM i LPARs for IBM Bob development environment. This automation handles everything from system prerequisites to project build, ensuring a consistent and reproducible setup across development and production environments.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Roles](#roles)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

This Ansible playbook automates the complete setup of an IBM i LPAR for IBM Bob development, including:

- ✅ Python 3.9 bootstrap (installed via raw SSH commands)
- ✅ System prerequisites verification
- ✅ YUM package manager setup
- ✅ Required package installation (9 packages: git, tn5250, service-commander, mapepire-server, etc.)
- ✅ Bash profile configuration
- ✅ Repository cloning from GitHub
- ✅ Database schema creation
- ✅ Project build and compilation

The playbook is designed to be **idempotent**, **modular**, and **production-ready**, with comprehensive error handling and detailed logging.

## Features

- **Automated Setup**: Complete LPAR preparation in a single command
- **Idempotent**: Safe to run multiple times without side effects
- **Modular Design**: 7 specialized roles for different setup phases
- **Tag-Based Execution**: Run specific parts of the setup as needed
- **Multi-Environment**: Separate configurations for development and production
- **Comprehensive Logging**: Detailed logs for troubleshooting
- **Error Handling**: Robust error detection and recovery
- **Validation**: Extensive verification at each step

## Prerequisites

### Control Node (Ansible Host)

- **Ansible**: Version 2.9 or higher
- **Python**: Version 3.6 or higher
- **SSH Client**: OpenSSH or compatible
- **Network Access**: Connectivity to IBM i systems

### IBM i LPAR (Target System)

- **IBM i Version**: 7.5 or higher (recommended)
- **SSH Server**: Running and accessible
- **PASE Environment**: Available and functional
- **User Profile**: With appropriate authorities:
  - SSH access
  - Authority to install packages
  - Authority to create directories and files
  - Authority to run PASE commands
  - (Optional) Authority to create database objects

### Network Requirements

- SSH access (port 22) from control node to IBM i
- Internet connectivity on IBM i for package downloads
- Access to GitHub for repository cloning

## Quick Start

### 1. Clone This Repository

```bash
git clone <repository-url>
cd bob-for-ibmi
```

### 2. Configure Inventory

Edit the inventory file for your environment:

```bash
# For development
vi inventory/development/hosts.yml

# For production
vi inventory/production/hosts.yml
```

Update these required fields:
- `ansible_host`: Your IBM i IP address or hostname
- `ansible_user`: SSH user with appropriate permissions
- `ansible_ssh_private_key_file`: Path to your SSH private key

### 3. Test Connectivity

```bash
# Test development environment
ansible -i inventory/development/hosts.yml ibmi_servers -m ping

# Test production environment
ansible -i inventory/production/hosts.yml ibmi_servers -m ping
```

### 4. Run the Playbook

```bash
# Full setup - development
ansible-playbook -i inventory/development/hosts.yml site.yml

# Full setup - production
ansible-playbook -i inventory/production/hosts.yml site.yml
```

## Project Structure

```
bob-for-ibmi/
├── README.md                          # This file
├── ansible.cfg                        # Ansible configuration
├── site.yml                          # Main playbook
├── group_vars/
│   └── all.yml                       # Global variables
├── inventory/
│   ├── README.md                     # Inventory documentation
│   ├── example-hosts.yml             # Template with all options
│   ├── development/
│   │   ├── hosts.yml                 # Development hosts
│   │   └── group_vars/
│   │       └── ibmi_servers.yml      # Development variables
│   └── production/
│       ├── hosts.yml                 # Production hosts
│       └── group_vars/
│           └── ibmi_servers.yml      # Production variables
├── roles/
│   ├── ibmi_prerequisites/           # System prerequisites
│   ├── ibmi_yum_setup/              # YUM package manager
│   ├── ibmi_packages/               # Package installation
│   ├── ibmi_bash_profile/           # Bash profile configuration
│   ├── ibmi_repository/             # Git repository cloning
│   ├── ibmi_database/               # Database schema creation
│   └── ibmi_project_build/          # Project build
└── docs/
    └── ansible-design.md            # Detailed design documentation
```

## Installation

### 1. Install Ansible

**On Linux/macOS:**
```bash
pip install ansible
```

**On Windows:**
```bash
# Use WSL (Windows Subsystem for Linux)
wsl --install
# Then install Ansible in WSL
pip install ansible
```

### 2. Verify Installation

```bash
ansible --version
```

### 3. Configure SSH Keys

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_ibmi

# Copy public key to IBM i
ssh-copy-id -i ~/.ssh/id_rsa_ibmi.pub user@ibmi-host

# Test SSH connection
ssh -i ~/.ssh/id_rsa_ibmi user@ibmi-host
```

## Configuration

### Global Variables

Edit `group_vars/all.yml` to configure global settings:

```yaml
# Target user configuration
target_user: "{{ ansible_user }}"
target_home: "/home/{{ target_user }}"

# Repository configuration
repository_url: "https://github.com/IBM/ibmi-company_system"
repository_version: "main"

# Database configuration
sql_schema: "SAMCOn"

# Build configuration
build_command: "/QOpenSys/pkgs/bin/makei build"
build_timeout: 600
```

### Environment-Specific Variables

Edit environment-specific variables in:
- `inventory/development/group_vars/ibmi_servers.yml`
- `inventory/production/group_vars/ibmi_servers.yml`

### Ansible Configuration

The `ansible.cfg` file contains optimized settings for IBM i:

- Default inventory: `inventory/production/hosts.yml`
- SSH pipelining enabled for performance
- YAML output format for readability
- Fact caching for faster execution
- Detailed logging to `/tmp/ansible-ibmi.log`

## Usage

### Full Setup

Run the complete playbook to set up everything:

```bash
# Development environment
ansible-playbook -i inventory/development/hosts.yml site.yml

# Production environment
ansible-playbook -i inventory/production/hosts.yml site.yml
```

### Tag-Based Execution

Run specific parts of the setup using tags:

```bash
# Only prerequisites and packages
ansible-playbook -i inventory/development/hosts.yml site.yml --tags "prerequisites,packages"

# Only repository and build
ansible-playbook -i inventory/development/hosts.yml site.yml --tags "repository,build"

# Skip database setup
ansible-playbook -i inventory/development/hosts.yml site.yml --skip-tags "database"
```

### Available Tags

- `prerequisites` - System prerequisites verification
- `setup` - Initial setup tasks (prerequisites, yum, packages)
- `yum` - YUM package manager setup
- `packages` - Package installation
- `profile` - Bash profile configuration
- `config` - Configuration tasks
- `repository` - Git repository cloning
- `git` - Git-related tasks
- `database` - Database schema creation
- `sql` - SQL-related tasks
- `build` - Project build
- `compile` - Compilation tasks

### Limit to Specific Hosts

```bash
# Run on a single host
ansible-playbook -i inventory/production/hosts.yml site.yml --limit ibmi-prod-01

# Run on multiple hosts
ansible-playbook -i inventory/production/hosts.yml site.yml --limit ibmi-prod-01,ibmi-prod-02
```

### Check Mode (Dry Run)

Preview changes without making them:

```bash
ansible-playbook -i inventory/development/hosts.yml site.yml --check
```

### Verbose Output

Increase verbosity for troubleshooting:

```bash
# Basic verbosity
ansible-playbook -i inventory/development/hosts.yml site.yml -v

# More detail
ansible-playbook -i inventory/development/hosts.yml site.yml -vv

# Debug level
ansible-playbook -i inventory/development/hosts.yml site.yml -vvv
```

## Roles

The playbook consists of 7 specialized roles that execute in sequence:

### 1. ibmi_prerequisites

**Purpose**: Verify system prerequisites and prepare the environment

**Tasks**:
- Verify SSH connectivity
- Gather system facts
- Check IBM i version (7.5+ recommended)
- Verify PASE environment
- Check bash shell availability
- Create required directories
- Verify user authorities

**Documentation**: [`roles/ibmi_prerequisites/README.md`](roles/ibmi_prerequisites/README.md)

### 2. ibmi_yum_setup

**Purpose**: Configure and verify YUM package manager

**Tasks**:
- Check if YUM is installed
- Download and run bootstrap script if needed
- Update repository metadata
- Verify YUM functionality
- Optimize YUM configuration

**Documentation**: [`roles/ibmi_yum_setup/README.md`](roles/ibmi_yum_setup/README.md)

### 3. ibmi_packages

**Purpose**: Install required open-source packages

**Packages Installed**:
- git - Version control
- tn5250 - Terminal emulator
- service-commander - Service management
- mapepire-server - Database connectivity
- rsync - File synchronization
- ibmichroot - Chroot environment
- nano - Text editor
- tobi - IBM i tools
- python39-itoolkit.ppc64 - Python interface to IBM i XMLSERVICE

**Note**: Python 3.9 is installed separately in Phase 0 (Pre-Bootstrap) using raw SSH commands before any Ansible modules execute.

**Documentation**: [`roles/ibmi_packages/README.md`](roles/ibmi_packages/README.md)

### 4. ibmi_bash_profile

**Purpose**: Configure user's bash profile with required environment variables

**Configuration**:
- Custom colored prompt (PS1)
- PATH with `/QOpenSys/pkgs/bin` priority
- UTF-8 encoding (LANG)
- Backup of existing profile

**Documentation**: [`roles/ibmi_bash_profile/README.md`](roles/ibmi_bash_profile/README.md)

### 5. ibmi_repository

**Purpose**: Clone the IBM i company system repository from GitHub

**Tasks**:
- Verify git installation
- Clone repository (or update if exists)
- Set proper ownership and permissions
- Verify repository integrity
- Get current commit information

**Documentation**: [`roles/ibmi_repository/README.md`](roles/ibmi_repository/README.md)

### 6. ibmi_database

**Purpose**: Create database sample schema (SAMCOn)

**Tasks**:
- Verify database connectivity
- Check if schema exists
- Create SQL sample schema
- Grant authorities to user
- Verify schema creation
- List created tables

**Documentation**: [`roles/ibmi_database/README.md`](roles/ibmi_database/README.md)

### 7. ibmi_project_build

**Purpose**: Build the project using makei

**Tasks**:
- Verify makei availability
- Check project directory and makefile
- Execute build command
- Capture build output
- Verify build success
- List build artifacts

**Documentation**: [`roles/ibmi_project_build/README.md`](roles/ibmi_project_build/README.md)

## Documentation

### Comprehensive Documentation

- **[Design Documentation](docs/ansible-design.md)** - Detailed architecture, design decisions, and technical specifications
- **[Inventory Documentation](inventory/README.md)** - Complete guide to inventory configuration and management
- **Role READMEs** - Each role has detailed documentation in its README.md file

### Key Documentation Topics

- Architecture and design principles
- IBM i-specific considerations
- Variable hierarchy and configuration
- Error handling and idempotency
- Execution flow and timing
- Testing strategy
- Security considerations
- Performance tuning

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to IBM i via SSH

**Solutions**:
1. Verify SSH service is running: `STRTCPSVR SERVER(*SSHD)`
2. Check firewall rules allow port 22
3. Verify SSH key permissions (600 for private key)
4. Test manual connection: `ssh -i ~/.ssh/id_rsa_ibmi user@host`

### Authentication Issues

**Problem**: Permission denied (publickey)

**Solutions**:
1. Verify public key is in `~/.ssh/authorized_keys` on IBM i
2. Check file permissions:
   - `~/.ssh` should be 700
   - `~/.ssh/authorized_keys` should be 600
3. Verify correct private key path in inventory

### Python Issues

**Problem**: `/usr/bin/python: not found`

**Solutions**:
1. Install Python3: `yum install python3`
2. Verify `ansible_python_interpreter` in inventory
3. Check Python path: `which python3`

### YUM Bootstrap Fails

**Problem**: YUM installation fails

**Solutions**:
1. Check internet connectivity
2. Verify proxy settings if behind firewall
3. Ensure sufficient disk space in `/QOpenSys/pkgs`
4. Check bootstrap script URL is accessible

### Package Installation Fails

**Problem**: Package installation errors

**Solutions**:
1. Update YUM cache: `yum makecache`
2. Check disk space: `df -h /QOpenSys/pkgs`
3. Verify network connectivity
4. Review package-specific errors in verbose output

### Build Fails

**Problem**: Project build fails

**Solutions**:
1. Review build log: `cat ~/ibmi-company_system/build.log`
2. Verify makei is installed: `which makei`
3. Check user has authority to create objects
4. Ensure all dependencies are installed

### Detailed Troubleshooting

For more troubleshooting information, see:
- [Inventory README - Troubleshooting Section](inventory/README.md#troubleshooting)
- [Design Documentation - Error Handling](docs/ansible-design.md#error-handling-and-idempotency)
- Individual role README files

### Getting Help

1. Check verbose output: `ansible-playbook ... -vvv`
2. Review log file: `/tmp/ansible-ibmi.log`
3. Check role-specific logs in user's home directory
4. Consult role-specific README files
5. Review design documentation for architecture details

## Contributing

### Adding New Roles

1. Create role directory: `mkdir -p roles/new_role/{tasks,defaults,templates}`
2. Create role files following existing patterns
3. Add role to `site.yml` with appropriate tags
4. Create comprehensive README.md for the role
5. Test thoroughly in development environment

### Modifying Existing Roles

1. Review role's README.md for current behavior
2. Make changes following existing patterns
3. Update role's README.md if behavior changes
4. Test in development environment
5. Update main documentation if needed

### Documentation Standards

- Use clear, concise language
- Include code examples
- Document all variables
- Explain error handling
- Provide troubleshooting tips
- Keep README files up to date

## License

This project is created for IBM Bob for IBM i setup automation.

---

## Workflow Summary

The complete setup workflow:

1. **Pre-Bootstrap** → Install Python 3.9 using raw SSH commands (no Python required)
2. **Prerequisites** → Verify system meets requirements
3. **YUM Setup** → Install/configure package manager
4. **Packages** → Install required open-source tools (9 packages)
5. **Bash Profile** → Configure user environment
6. **Repository** → Clone project from GitHub
7. **Database** → Create sample schema
8. **Build** → Compile project

**Total Execution Time**: Approximately 15-25 minutes for first run, 5-10 minutes for subsequent runs.

## Quick Reference

### Common Commands

```bash
# Full setup
ansible-playbook -i inventory/development/hosts.yml site.yml

# Check mode (dry run)
ansible-playbook -i inventory/development/hosts.yml site.yml --check

# Only install packages
ansible-playbook -i inventory/development/hosts.yml site.yml --tags packages

# Skip database setup
ansible-playbook -i inventory/development/hosts.yml site.yml --skip-tags database

# Verbose output
ansible-playbook -i inventory/development/hosts.yml site.yml -vvv

# Limit to specific host
ansible-playbook -i inventory/production/hosts.yml site.yml --limit ibmi-prod-01
```

### Important Files

- `site.yml` - Main playbook
- `ansible.cfg` - Ansible configuration
- `group_vars/all.yml` - Global variables
- `inventory/*/hosts.yml` - Host definitions
- `/tmp/ansible-ibmi.log` - Execution log

### Support Resources

- Design Documentation: [`docs/ansible-design.md`](docs/ansible-design.md)
- Inventory Guide: [`inventory/README.md`](inventory/README.md)
- Role Documentation: `roles/*/README.md`

---

**Made with Bob** 🤖