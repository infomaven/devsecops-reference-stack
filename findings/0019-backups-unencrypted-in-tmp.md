# 0019. Database backups are unencrypted under a predictable `/tmp` path

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-311 (missing encryption of sensitive data), CWE-377 (insecure temporary file)
- **Severity:** Low locally (fake data). In the system this models, a full copy of the payments database sits in a world-traversable directory.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

- `ansible/group_vars/all.yml:27` sets `backup_dir: /tmp/pg_backups`. The
  directory is created `0700` (`db_backup.yml:9-13`), but the path is
  fixed and under `/tmp`, so another local user can create it first.
- `ansible/db_backup.yml:16-22` writes each dump to `/tmp/<name>.dump`
  inside the container, and nothing removes those copies after
  `docker cp`.
- The dumps are plain `pg_dump` custom format, with no encryption at rest.

## How it got here

Deliberate demo tradeoff. `/tmp` needs no setup and no privilege
escalation, which `ansible.cfg` turns off.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
