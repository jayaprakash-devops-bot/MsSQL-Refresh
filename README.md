# MSSQL Refresh Automation

This playbook orchestrates the preparation required to refresh a Microsoft SQL Server database from a source environment to a target environment. It supports SQL Server 2016 through 2022 deployments running either Availability Group (AG) or standalone configurations.

## What the workflow does

- Uses `community.general.mssql_script` to connect to the source and target instances and capture HA/DR topology (AG, mirroring, log shipping, backup compression state).
- Detects the current primary and secondary replicas for both the source and target listeners/aliases.
- Discovers the latest full, differential, and log backups available for the source database and produces an ordered restore plan that accounts for multi-node/failover scenarios.
- Captures target server logins, role memberships, database principals, and explicit permissions prior to the restore so they can be re-applied afterward.

## Requirements

- Ansible 2.15+ (or Automation Platform 2.4+).
- Python `pymssql` package available on the controller where the role runs.
- `community.general` collection (see `collections/requirements.yml`).
- Credentials for the SQL instances provided either directly (`sql_usr`/`sql_pwd`) or via the optional CyberArk role.

## Key variables

| Variable | Description |
| --- | --- |
| `src_instance` | Source SQL Server instance or listener name. |
| `src_database` | Source database name. |
| `dest_instance` | Target SQL Server instance or listener name. |
| `dest_database` | Target database name. |
| `mssql_refresh_backup_lookback_hours` | Look-back window used when scanning backup history (default 72). |
| `mssql_refresh_use_cyberark` | Toggle to retrieve credentials through the `CyberArk` role (default `true`). |
| `security_script_output` | Optional local directory to write the generated login/permission script. |

## Running the playbook

```bash
ansible-galaxy collection install -r collections/requirements.yml
ansible-playbook MsSQL_database_refresh.yml \
  -e src_instance=SQLSRC-LSN01 \
  -e src_database=MyDb \
  -e dest_instance=SQLTGT-LSN01 \
  -e dest_database=MyDb \
  -e dest_listener=SQLTGT-LSN01 \
  -e src_listener=SQLSRC-LSN01
```

The resulting plan is exposed as the fact `mssql_refresh_restore_plan`, which lists each restore step in order. Security scripts are rendered to memory and (optionally) written to `security_script_output`.

## Outputs

- `mssql_refresh_source_instance_info` / `mssql_refresh_target_instance_info` – server level HA/DR metadata.
- `mssql_refresh_source_replicas` / `mssql_refresh_target_replicas` – replica level information for AG deployments.
- `mssql_refresh_restore_plan` – ordered restore statements covering full/diff/log/with recovery.
- `mssql_refresh_security_script_text` – T-SQL statements to recreate logins, users, and permissions.

## Extending

The new `roles/mssql_refresh` role is modular: you can tag or selectively include `precheck.yml`, `backups.yml`, or `security.yml` depending on the workflow stage (for example, `--tags backups`). Additional checks (such as automating the restore itself) can be layered on top of the structured facts already compiled.
