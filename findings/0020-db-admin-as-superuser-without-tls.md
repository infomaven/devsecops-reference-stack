# 0020. All database administration runs as the superuser with no TLS mode set

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-250 (execution with unnecessary privileges), CWE-319 (cleartext transmission of sensitive information)
- **Severity:** Low locally (loopback connection). In the system this models, the superuser password crosses the network on every playbook run.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

Every `community.postgresql` task in `ansible/site.yml`,
`ansible/db_backup.yml`, and both roles logs in as `postgres_superuser`,
including routine migrations
(`roles/app_database/tasks/apply_migration.yml:13-20`). No task sets
`ssl_mode`, so the client default applies, which does not require TLS or
verify the server. `roles/postgres_server/defaults/main.yml` does not
enable `ssl` on the server.

The inventory comment (`inventory/hosts.ini:1-3`) says to swap in a real
inventory and the roles do not change. With a remote host, that means the
superuser password in transit without guaranteed encryption.

## How it got here

Generation default. One login for every task is the simplest form, and
the demo connects over loopback.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
