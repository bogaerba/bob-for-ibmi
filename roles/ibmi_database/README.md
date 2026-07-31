# Role: ibmi_database

## Description

This role executes SQL commands to create database sample schemas on IBM i using the `ibm.power_ibmi.ibmi_sql_execute` Ansible module. It creates the SAMCOn (Company System) sample schema using the IBM-provided `CREATE_SQL_SAMPLE` stored procedure, verifies the schema creation, and grants necessary authorities to the target user.

## Requirements

- Db2 for i must be accessible
- User must have authority to create schemas
- `ibm.power_ibmi` Ansible collection installed
- Sufficient database storage

## Role Variables

### Default Variables (defaults/main.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `sql_schema` | `SAMCOn` | Name of the schema to create |
| `sql_command` | `CALL QSYS.CREATE_SQL_SAMPLE('{{ sql_schema }}')` | SQL command to execute |
| `db_user` | `{{ target_user }}` | Database user for authority grants |
| `grant_authorities` | `true` | Whether to grant authorities to user |
| `log_database_operations` | `true` | Whether to log operations |

### Required Variables (from group_vars/all.yml)

| Variable | Description |
|----------|-------------|
| `target_user` | Target user for authority grants |
| `target_home` | Home directory for log files |

## Tasks Performed

1. **Verify Database Connectivity**: Tests connection to Db2 for i using SQL query
2. **Check Schema Existence**: Determines if schema already exists
3. **Create SQL Sample Schema**: Executes `CREATE_SQL_SAMPLE` stored procedure
4. **Verify Schema Creation**: Confirms schema was created successfully
5. **List Schema Tables**: Retrieves list of tables in the schema
6. **Count Tables**: Counts number of tables created
7. **Grant Authorities**: Grants necessary permissions to target user
8. **Create Summary**: Generates database setup summary
9. **Log Operations**: Records database operations to log file

## SQL Sample Schema (SAMCOn)

The SAMCOn schema is IBM's sample company system database that includes:
- Employee tables
- Department tables
- Project tables
- Sample data for testing and development

This schema is commonly used for:
- Learning SQL on IBM i
- Testing database applications
- Development and training purposes

## Dependencies

- **ibmi_prerequisites**: System must be accessible
- **ibm.power_ibmi collection**: Required for ibmi_sql_execute module
  - Install with: `ansible-galaxy collection install ibm.power_ibmi`

## Example Playbook

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_database
      tags: [database, sql]
```

## Example with Custom Schema

```yaml
- hosts: ibmi
  roles:
    - role: ibmi_database
      vars:
        sql_schema: "MYSCHEMA"
        sql_command: "CREATE SCHEMA MYSCHEMA"
```

## Tags

- `database`: All database tasks
- `sql`: SQL-related tasks
- `verify`: Verification tasks
- `check`: Schema existence checks
- `create`: Schema creation
- `info`: Information gathering
- `permissions`: Authority grants
- `logging`: Logging tasks

## Error Handling

- **Connectivity Check**: Verifies database is accessible before operations
- **Idempotency**: Checks if schema exists before creation
- **Graceful Handling**: Handles "already exists" errors gracefully
- **Verification**: Confirms schema creation after execution
- **Detailed Errors**: Provides SQL error messages for troubleshooting

## Idempotency

- Checks if schema exists before attempting creation
- Skips creation if schema already exists
- Safe to run multiple times
- Only grants authorities if needed

## Database Authorities

The role grants the following authorities to the target user:
- ALL privileges on the schema
- Ability to create, read, update, and delete objects
- Full access to all tables in the schema

## Important Notes

1. **Schema Creation Time**: Creating sample schemas may take 1-2 minutes depending on system load

2. **Storage Requirements**: Sample schemas require database storage space

3. **Existing Schemas**: If schema already exists, the role will skip creation and verify existing schema

4. **User Authorities**: Ensure the Ansible user has sufficient authorities to create schemas and grant permissions

## Verification

After running this role, verify the database setup using the ibmi_sql_execute module or command line:

```yaml
# Using Ansible ad-hoc command
ansible ibmi -m ibm.power_ibmi.ibmi_sql_execute -a "sql='SELECT SCHEMA_NAME FROM QSYS2.SYSSCHEMAS WHERE SCHEMA_NAME = \"SAMCOn\"'"
```

Or using system command line:
```bash
# Connect to database and check schema
system "RUNSQLSTM SRCSTMF('/tmp/check.sql')"
```

## Troubleshooting

### Database Connection Failed

- Verify Db2 for i is running
- Check user has database access
- Verify network connectivity to database
- Review system logs for database errors

### Schema Creation Failed

- Check user has CREATE SCHEMA authority
- Verify sufficient database storage
- Review SQL error messages
- Check for conflicting schema names

### Authority Grant Failed

- Verify user has GRANT authority
- Check target user exists
- Review security settings
- Ensure proper user profile configuration

### Schema Already Exists

- This is normal and expected on subsequent runs
- Role will verify existing schema
- No action needed unless schema is corrupted

## Performance Considerations

- Schema creation is a one-time operation
- Subsequent runs are fast (only verification)
- Sample data population may take time
- Consider database load during creation

## Security Considerations

- Schema creation requires elevated database privileges
- Authorities are granted to specific user only
- Sample schemas contain test data (not production)
- Review authority grants for production environments

## Log Files

Database operations are logged to:
- `~/.ibmi-bob-database.log` - Database setup history with timestamps

## Author

Generated for IBM Bob for IBM i project