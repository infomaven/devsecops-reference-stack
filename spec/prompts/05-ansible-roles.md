# P05: Ansible Postgres roles (F08, F09)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Implement F08 and F09 under `ansible/`.

Layout: `ansible.cfg`, `requirements.yml` (community.postgresql,
community.docker), `inventory/hosts.ini` with the local Postgres container
as a managed endpoint over its published port, `group_vars/all.yml` with
non-secret defaults referencing `vault_*` variables, `group_vars/vault.example.yml`
to copy and encrypt with ansible-vault, `site.yml` with a `pre_tasks` ping
that retries until the database answers, then the two roles.

`roles/postgres_server`: apply server settings from a dict (connection
logging, slow-query threshold, pg_stat_statements) with a reload handler;
create the application role and the read-only role with
`NOSUPERUSER,NOCREATEDB,NOCREATEROLE,LOGIN` and `no_log: true` (I7, I8).

`roles/app_database`: create each database with its owner; enable every
extension in each database's list (use `subelements`, not `first`); revoke
CREATE on the public schema from PUBLIC; grant default SELECT on tables to
the read-only role; create the migration ledger table.

Acceptance:
- `ansible-playbook --syntax-check -i ansible/inventory/hosts.ini ansible/site.yml` passes
- `ansible-lint ansible` passes
- Against a running Postgres container: the playbook runs twice and the
  second run reports changed=0
- `grep -rn "no_log: true" ansible/roles/postgres_server/tasks/main.yml | wc -l` is 2
