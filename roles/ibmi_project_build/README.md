# Role: ibmi_project_build

## Description

This role builds the ibmi-company_system project using the `makei` build tool. It verifies prerequisites, executes the build command, captures build output, verifies build success, and records build artifacts.

## Requirements

- `makei` build tool must be installed
- Project repository must be cloned
- Makefile must exist in project directory
- Sufficient system resources for compilation
- User must have authority to create objects

## Role Variables

### Default Variables (defaults/main.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `project_dir` | `{{ repository_dest }}` | Project directory path |
| `build_command` | `/QOpenSys/pkgs/bin/makei build` | Build command to execute |
| `build_log` | `{{ project_dir }}/build.log` | Build log file location |
| `build_timeout` | `600` | Build timeout in seconds (10 minutes) |
| `force_rebuild` | `false` | Whether to force clean rebuild |
| `makei_executable` | `/QOpenSys/pkgs/bin/makei` | Path to makei binary |
| `build_artifact_patterns` | `*.pgm, *.srvpgm, *.bnddir` | Patterns for build artifacts |

### Required Variables (from group_vars/all.yml)

| Variable | Description |
|----------|-------------|
| `repository_dest` | Repository location (project directory) |
| `target_home` | Home directory for log files |

## Tasks Performed

1. **Verify makei Availability**: Confirms makei is installed and executable
2. **Verify Project Directory**: Ensures project directory exists
3. **Check Makefile**: Verifies makefile exists in project
4. **Check Existing Artifacts**: Lists any existing build artifacts
5. **Clean Previous Build**: Optionally cleans previous build (if force_rebuild)
6. **Execute Build**: Runs the makei build command
7. **Display Build Output**: Shows build output and any errors
8. **Save Build Log**: Writes build output to log file
9. **Verify Build Success**: Confirms build completed successfully
10. **Find Build Artifacts**: Locates created build artifacts
11. **Create Summary**: Generates build summary with statistics
12. **Record Completion**: Logs build completion

## Build Process

The role executes the following build command:
```bash
cd <project_dir> && /QOpenSys/pkgs/bin/makei build
```

This command:
- Changes to the project directory
- Executes makei with the 'build' target
- Compiles source code into IBM i objects
- Creates programs, service programs, and binding directories

## Dependencies

- **ibmi_prerequisites**: System must be accessible
- **ibmi_packages**: makei must be installed (typically part of build tools)
- **ibmi_repository**: Project must be cloned

## Example Playbook

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_project_build
      tags: [build, compile]
```

## Example with Force Rebuild

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_project_build
      vars:
        force_rebuild: true
      tags: [build, compile]
```

## Example with Custom Build Command

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_project_build
      vars:
        build_command: "/QOpenSys/pkgs/bin/makei build -j4"  # Parallel build
        build_timeout: 1200  # 20 minutes
```

## Tags

- `build`: All build tasks
- `compile`: Compilation tasks
- `verify`: Verification tasks
- `check`: Pre-build checks
- `clean`: Clean tasks
- `info`: Information gathering
- `logging`: Logging tasks

## Error Handling

- **Prerequisites Check**: Verifies makei and project directory before building
- **Async Execution**: Build runs asynchronously with timeout
- **Output Capture**: Captures both stdout and stderr
- **Build Verification**: Asserts build completed successfully
- **Detailed Logging**: Saves complete build output to log file

## Idempotency

- Checks for existing artifacts before building
- Build tools (makei) handle incremental builds
- Only rebuilds changed files (unless force_rebuild is true)
- Safe to run multiple times

## Build Artifacts

The role searches for the following artifact types:
- **\*.pgm** - Program objects
- **\*.srvpgm** - Service program objects
- **\*.bnddir** - Binding directory objects

These artifacts are:
- Counted and reported
- Listed in debug output
- Logged for reference

## Important Notes

1. **Build Time**: Initial builds may take 5-10 minutes depending on project size and system load

2. **Incremental Builds**: Subsequent builds are faster as only changed files are recompiled

3. **Force Rebuild**: Set `force_rebuild: true` to clean and rebuild everything

4. **Build Timeout**: Default timeout is 10 minutes; increase for large projects

5. **Parallel Builds**: Consider using `-j` flag with makei for faster builds on multi-core systems

## Build Output

Build output is saved to:
- **Console**: Displayed during Ansible execution
- **Build Log**: `<project_dir>/build.log` - Complete build output
- **History Log**: `~/.ibmi-bob-build.log` - Build history with timestamps

## Verification

After running this role, verify the build:

```bash
# Check build log
cat ~/ibmi-company_system/build.log

# List build artifacts
find ~/ibmi-company_system -name "*.pgm" -o -name "*.srvpgm"

# Check object library
system "DSPLIB LIB(YOURLIB)"

# Verify specific program
system "DSPPGM PGM(YOURLIB/YOURPGM)"
```

## Troubleshooting

### makei Not Found

- Verify makei is installed: `which makei`
- Install build tools if missing
- Check PATH includes `/QOpenSys/pkgs/bin`

### Build Fails with Compilation Errors

- Review build log: `cat <project_dir>/build.log`
- Check source code for syntax errors
- Verify all dependencies are available
- Ensure user has authority to create objects

### Build Timeout

- Increase `build_timeout` value
- Check system resources (CPU, memory)
- Consider parallel build with `-j` flag
- Review for infinite loops or hanging processes

### Makefile Not Found

- Verify repository was cloned correctly
- Check project directory path
- Ensure makefile exists in project root
- Review repository structure

### Permission Denied

- Verify user has authority to create objects
- Check library authorities
- Ensure write access to project directory
- Review user profile settings

## Performance Considerations

- Initial build: 5-10 minutes (full compilation)
- Incremental build: 1-3 minutes (only changed files)
- Parallel builds can reduce time by 50-70%
- System load affects build time
- Network file systems may slow builds

## Build Optimization

To optimize build performance:

1. **Use Parallel Builds**: Add `-j4` to build_command
2. **Increase Timeout**: For large projects
3. **Local Storage**: Build on local disk, not network
4. **System Resources**: Ensure adequate CPU and memory
5. **Incremental Builds**: Avoid force_rebuild unless necessary

## Security Considerations

- Build process creates objects in user's library
- Ensure proper library authorities
- Review source code before building
- Build artifacts should be tested before production use

## Log Files

Build operations are logged to:
- `<project_dir>/build.log` - Complete build output
- `~/.ibmi-bob-build.log` - Build history with timestamps

## Author

Generated for IBM Bob for IBM i project