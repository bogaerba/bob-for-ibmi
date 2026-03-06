# Role: ibmi_repository

## Description

This role clones the IBM i company system repository from GitHub. It handles both initial cloning and updates of existing repositories, sets proper ownership and permissions, and verifies repository integrity.

## Requirements

- Git must be installed (`/QOpenSys/pkgs/bin/git`)
- Internet connectivity to access GitHub
- Sufficient disk space for repository
- User home directory must exist

## Role Variables

### Default Variables (defaults/main.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `repository_url` | `https://github.com/IBM/ibmi-company_system` | GitHub repository URL |
| `repository_dest` | `{{ target_home }}/ibmi-company_system` | Local destination path |
| `repository_version` | `main` | Branch, tag, or commit to checkout |
| `repository_force` | `false` | Whether to discard local changes |
| `repository_update` | `true` | Whether to update existing repository |
| `git_executable` | `/QOpenSys/pkgs/bin/git` | Path to git binary |

### Required Variables (from group_vars/all.yml)

| Variable | Description |
|----------|-------------|
| `target_user` | Target user for repository ownership |
| `target_home` | Home directory for repository location |

## Tasks Performed

1. **Verify Git Installation**: Confirms git is available and functional
2. **Check Repository Existence**: Determines if repository already exists
3. **Clone Repository**: Clones repository if not present
4. **Update Repository**: Updates existing repository to latest version
5. **Get Repository Information**: Retrieves current commit and branch information
6. **Set Ownership**: Ensures correct user ownership of repository files
7. **Set Permissions**: Sets appropriate file permissions
8. **Verify Integrity**: Checks repository status and important files
9. **Create Summary**: Generates repository setup summary

## Dependencies

- **ibmi_prerequisites**: Home directory must exist
- **ibmi_packages**: Git must be installed

## Example Playbook

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_repository
      tags: [repository, git]
```

## Example with Custom Repository

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_repository
      vars:
        repository_url: "https://github.com/myorg/myrepo"
        repository_dest: "/home/myuser/myrepo"
        repository_version: "develop"
```

## Tags

- `repository`: All repository tasks
- `git`: Git-related tasks
- `verify`: Verification tasks
- `clone`: Repository cloning
- `update`: Repository updates
- `info`: Information gathering
- `permissions`: Permission setting

## Error Handling

- **Git Verification**: Fails if git is not installed
- **Clone Failures**: Provides detailed error messages for clone issues
- **Integrity Checks**: Verifies important files exist after clone/update
- **Network Issues**: Git module handles network timeouts and retries

## Idempotency

- Checks if repository exists before cloning
- Uses git module's built-in idempotency for updates
- Only updates if remote has changes
- Safe to run multiple times

## Repository Structure Verification

The role verifies the following files exist after cloning:
- `README.md` - Repository documentation
- `makefile` - Build configuration
- `.git` - Git metadata directory

## Important Notes

1. **First Clone**: Initial clone may take several minutes depending on repository size and network speed

2. **Updates**: Subsequent runs will update the repository to the latest version unless `repository_update: false`

3. **Local Changes**: By default, local changes are preserved. Set `repository_force: true` to discard them

4. **Branch Switching**: Change `repository_version` to switch branches or checkout specific commits

## Repository Information

After running this role, the following information is available:
- Repository URL
- Local destination path
- Current branch
- Latest commit hash and message
- Repository status (cloned/updated/up-to-date)

## Verification

After running this role, verify the repository:

```bash
# Check repository exists
ls -la ~/ibmi-company_system

# Check git status
cd ~/ibmi-company_system
git status

# View current branch
git branch

# View latest commit
git log -1
```

## Troubleshooting

### Clone Fails with Network Error

- Check internet connectivity
- Verify GitHub is accessible: `ping github.com`
- Check proxy settings if behind firewall
- Try cloning manually to diagnose: `git clone <url>`

### Permission Denied

- Verify user has write access to destination directory
- Check parent directory permissions
- Ensure user ownership is correct

### Repository Already Exists Error

- Role handles existing repositories automatically
- If issues persist, manually remove directory and re-run
- Check for file locks or processes using the directory

### Local Changes Conflict

- Set `repository_force: true` to discard local changes
- Or manually commit/stash changes before running
- Review git status to understand conflicts

## Performance Considerations

- Initial clone time depends on repository size (typically 1-5 minutes)
- Updates are faster, only fetching new changes
- Large repositories may require significant disk space

## Security Considerations

- Uses HTTPS for public repositories (no authentication required)
- For private repositories, configure SSH keys or access tokens
- Repository URL should use HTTPS for security

## Author

Generated for IBM Bob for IBM i project