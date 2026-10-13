# 0010. The append-only audit grant does not exist

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-732 (incorrect permission assignment for critical resource)
- **Severity:** Medium in the system this models: the tamper-evidence the audit table is meant to provide is not enforced by anything. Locally the application is a placeholder and writes nothing.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`db/migrations/V003__audit_trail.sql:1-2` says the application role "can
insert but not update or delete; the grant lives in the Ansible role, not
here". No such grant exists. `ansible/roles/app_database/tasks/main.yml`
revokes `CREATE` on `public` from `PUBLIC` and grants default `SELECT` to
the read-only role, and grants nothing to `paymentsvc_app` on any table.

Confirmed: the grant is absent. Not confirmed: the application role's
effective privileges. It owns each database (`all.yml:10`), and on
Postgres 15 and later the database owner controls the `public` schema,
so what it can do to tables created by the superuser needs checking
against a running instance.

## How it got here

Missing guardrail. The control was described in a comment in one tool and
left to be implemented in another, and nothing tests the resulting
privileges.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
