# 0018. Ansible collections are unpinned

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-829 (inclusion of functionality from untrusted control sphere)
- **Severity:** Low. The collections run with the Postgres superuser password, and their version is whatever Galaxy serves on the day.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`ansible/requirements.yml:4,6` require `community.postgresql >=3.4.0` and
`community.docker >=3.10.0`. A lower bound with no upper bound and no
lock means each install takes the newest release. Every task in the
roles passes `postgres_superuser_password` to these modules.

## How it got here

Generation default. `>=` is the form most Ansible examples use.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
