# 0009. One database role and one password across dev, staging, and prod

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-269 (improper privilege management)
- **Severity:** Medium in the system this models: a leaked dev credential opens the prod database. Locally all three databases hold fake data on one container.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`ansible/group_vars/all.yml:8-25` creates `paymentsvc_dev`,
`paymentsvc_staging`, and `paymentsvc_prod` on one server, all owned by
the single role `paymentsvc_app` with one password
(`vault_app_db_password`). The read-only role is shared the same way.

`.github/workflows/scheduled-drift.yml:31` has the same shape: the job
sets no `environment`, so `secrets.DB_PASSWORD` is one repository-level
value used for all three matrix legs.

`docs/SECRETS.md:7-8` says "the environments do not share keys". That
holds for the SOPS files and does not hold for the database roles.

## How it got here

Deliberate demo tradeoff that was never written down. One Postgres
container stands in for three environments; the role model followed the
container rather than the environments.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
