# 0013. `.gitignore` does not cover the Ansible secrets the repo tells you to create

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-312 (cleartext storage of sensitive information)
- **Severity:** Medium. Nothing is exposed today; the risk is one forgotten `ansible-vault encrypt` away from three database passwords in history.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`ansible/group_vars/vault.example.yml:2-5` tells the reader to copy the
file to `vault.yml`, encrypt it, and use "a vault password file that is
gitignored". `.gitignore` contains no entry for
`ansible/group_vars/vault.yml` or for any vault password file. It also
has no entry for `*.tfvars` or `*.dump`.

Both playbooks load `group_vars/vault.yml` (`site.yml:6`,
`db_backup.yml:6`), and that file does not exist in the tree, so the
first thing anyone running the demo does is create it.

## How it got here

Missing guardrail. The documentation describes the ignore rule and the
ignore file was written separately. gitleaks is the stated backstop, but
it matches secret-shaped strings, and `change-me-in-vault` style values
or a short real password may not match.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
