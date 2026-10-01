# ibmi_copy_libraries

Copies the **SAMCON** and **SAMSRCN** library templates `n` times on the IBM i LPAR using the
`3_copy_lib_n_times.sh` script shipped with the
[IBM-i-Application-Modernization-with-Bob](https://github.com/bmarolleau/IBM-i-Application-Modernization-with-Bob)
repository.

## What it does

Runs the following two commands on the IBM i LPAR:

```bash
./3_copy_lib_n_times.sh --from SAMCON  --range 1 <n> --base SAMCO
./3_copy_lib_n_times.sh --from SAMSRCN --range 1 <n> --base SAMSRC
```

This produces libraries `SAMCO1`…`SAMCO<n>` and `SAMSRC1`…`SAMSRC<n>`.

## Variables

| Variable | Default | Description |
|---|---|---|
| `ibmi_library_count` | `1` | Number of library copies to create. Provided interactively via `vars_prompt` in the play. |
| `ibmi_setup_scripts_dir` | `{{ repository_dest }}/setup` | Absolute IFS path to the directory containing `3_copy_lib_n_times.sh`. |

## Tags

| Tag | Purpose |
|---|---|
| `copy_libraries` | All tasks in this role |
| `samcon` | Tasks related to the SAMCON copy |
| `samsrcn` | Tasks related to the SAMSRCN copy |
| `validate` | Input validation tasks |
| `verify` | Script/directory existence checks |

## Usage

The role is invoked by the **Play 3 – Copy Libraries** play in `site.yml`, which prompts
the operator for the library count before connecting to the IBM i host:

```bash
# Run only the library-copy play
ansible-playbook site.yml --tags copy_libraries

# Skip the copy play and run everything else
ansible-playbook site.yml --skip-tags copy_libraries
```

You can also pass the count non-interactively:

```bash
ansible-playbook site.yml --tags copy_libraries -e ibmi_library_count=3
```

## Made with Bob
