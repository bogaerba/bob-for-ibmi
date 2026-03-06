# Role: ibmi_bash_profile

## Description

This role configures the user's bash profile with required environment variables for IBM Bob. It sets up the shell prompt (PS1), PATH to include open-source tools, and LANG for UTF-8 encoding. The role ensures proper backup of existing configurations and validates the new profile.

## Requirements

- Bash shell installed at `/QOpenSys/pkgs/bin/bash`
- User home directory exists
- Write permissions to user's home directory

## Role Variables

### Default Variables (defaults/main.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `bash_profile_path` | `{{ target_home }}/.bash_profile` | Path to bash profile file |
| `bash_ps1` | `\e[1;34m[\u@\h \W]\$ \e[m` | Shell prompt format (blue colored) |
| `bash_path` | `/QOpenSys/pkgs/bin:$PATH` | PATH configuration |
| `bash_lang` | `EN_US.UTF-8` | Language/encoding setting |
| `backup_suffix` | `.ansible-backup` | Suffix for backup files |
| `bash_profile_custom_content` | undefined | Optional custom content to append |

### Required Variables (from group_vars/all.yml)

| Variable | Description |
|----------|-------------|
| `target_user` | Target user for the setup |
| `target_home` | Home directory of the target user |

## Tasks Performed

1. **Check Existing Profile**: Verifies if .bash_profile already exists
2. **Backup Existing Profile**: Creates backup of existing profile if present
3. **Create Profile from Template**: Generates new .bash_profile from Jinja2 template
4. **Verify Syntax**: Validates bash syntax of the new profile
5. **Source Profile**: Tests profile by sourcing it
6. **Verify PATH**: Confirms PATH includes `/QOpenSys/pkgs/bin`
7. **Verify LANG**: Confirms LANG is set to UTF-8
8. **Verify PS1**: Confirms custom prompt is configured
9. **Create Summary**: Generates configuration summary

## Template

The role uses a Jinja2 template (`templates/bash_profile.j2`) that configures:

- **PS1**: Custom colored prompt showing `[user@host directory]$`
- **PATH**: Prepends `/QOpenSys/pkgs/bin` to ensure open-source tools are found first
- **LANG**: Sets UTF-8 encoding for proper character support

## Dependencies

- **ibmi_prerequisites**: Home directory must exist
- **ibmi_packages**: Bash should be installed (though it's typically pre-installed)

## Example Playbook

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_bash_profile
      tags: [profile, config]
```

## Example with Custom Content

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_bash_profile
      vars:
        bash_profile_custom_content: |
          # Custom aliases
          alias ll='ls -la'
          alias gs='git status'
          
          # Custom environment variables
          export EDITOR=nano
```

## Tags

- `profile`: All profile configuration tasks
- `config`: Configuration tasks
- `backup`: Backup tasks
- `verify`: Verification tasks

## Error Handling

- **Backup Creation**: Existing profiles are backed up before modification
- **Syntax Validation**: Profile syntax is checked before deployment
- **Source Testing**: Profile is sourced to ensure it loads without errors
- **Idempotent**: Safe to run multiple times

## Idempotency

- Uses template module which only updates if content changes
- Automatic backup prevents data loss
- Verification steps ensure profile is valid

## Important Notes

1. **Profile Activation**: The new bash profile becomes active on next login. To activate immediately:
   ```bash
   source ~/.bash_profile
   ```

2. **Backup Location**: Original profile is backed up to `~/.bash_profile.ansible-backup`

3. **Custom Content**: Use `bash_profile_custom_content` variable to add custom configurations without modifying the template

4. **PATH Priority**: `/QOpenSys/pkgs/bin` is prepended to PATH, giving open-source tools priority over system tools

## Verification

After running this role, verify the configuration:

```bash
# Check PATH
echo $PATH

# Check LANG
echo $LANG

# Check PS1
echo $PS1

# Verify git is in PATH
which git
```

## Troubleshooting

### Profile Not Loading

- Check file permissions: `ls -la ~/.bash_profile`
- Verify syntax: `bash -n ~/.bash_profile`
- Check for errors: `bash -x ~/.bash_profile`

### PATH Not Updated

- Ensure profile is sourced: `source ~/.bash_profile`
- Check for conflicting PATH settings in other files
- Verify `/QOpenSys/pkgs/bin` exists

### Custom Prompt Not Showing

- Check terminal supports ANSI colors
- Verify PS1 variable: `echo $PS1`
- Try simpler prompt format if colors don't work

## Author

Generated for IBM Bob for IBM i project