# 0001. Postgres superuser published on all interfaces with a known password

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-668 (exposure of resource to wrong sphere), CWE-1392 (use of default credentials)
- **Severity:** High. This is the one finding with real blast radius on the demo machine itself: it does not depend on CI running.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`Makefile:16` starts the database with `-p 5432:5432`, which Docker binds
to 0.0.0.0, and sets the superuser password to `bootstrap`. The Ansible
inventory (`ansible/inventory/hosts.ini:5`) assumes 127.0.0.1. Anyone on
the same network as the laptop can connect as `postgres`/`bootstrap` and
read or change every database on the server.

## How it got here

Deliberate tradeoff, half revisited. `docs/REVIEW_NOTES.md` and
`docs/EXERCISE.md` accept the `bootstrap` password as a documented demo
convenience. Neither mentions the bind address, which is Docker's default
for a bare `-p` mapping.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
