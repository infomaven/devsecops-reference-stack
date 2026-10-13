# 0003. Deploy workflows use mutable action tags

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-829 (inclusion of functionality from untrusted control sphere); OWASP CICD-SEC-3
- **Severity:** High in the system this models: the affected jobs include the one that holds the SOPS age private key and applies to prod. No effect locally.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

Actions are referenced by tag rather than commit SHA in:

- `.github/workflows/apply.yml:23,25`
- `.github/workflows/pr-checks.yml:21,22,27,66,67,95,96,117`
- `.github/workflows/scheduled-drift.yml:23,24,37`

A tag can be re-pointed. If one is, the replaced action runs inside a job
that has `SOPS_AGE_KEY` or `DB_PASSWORD` available. Only the
`iac-security` job in `pr-checks.yml` and the copied `security-scan.yml`
pin by SHA.

## How it got here

Inconsistent application of the repo's own rule. `pr-checks.yml:48-49`
states "A tag can be force-pushed; a SHA cannot", and the comment at
lines 40-43 describes SHA pinning as the standard. The other jobs were
generated with the common tag form and never brought in line.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
