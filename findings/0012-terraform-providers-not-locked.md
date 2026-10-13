# 0012. Terraform providers are not locked

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-829 (inclusion of functionality from untrusted control sphere)
- **Severity:** Medium in the system this models: provider code runs with cluster credentials and the database password, and its version and hash are not fixed. Low locally.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`terraform/envs/{dev,staging,prod}/main.tf:5-12` constrain the
`kubernetes` and `helm` providers with ranges (`~> 2.31`, `~> 2.15`).
There is no committed `.terraform.lock.hcl` in any environment, and
`scripts/demo-reset.sh:9` deletes any lock file that `terraform init`
creates. Each `init`, locally and in CI, accepts whatever build matches
the range, with no recorded hash to compare against.

## How it got here

Deliberate tradeoff that was never revisited. The reset script removes
lock files so rehearsals start clean, which also removes the only
integrity record for the providers.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
