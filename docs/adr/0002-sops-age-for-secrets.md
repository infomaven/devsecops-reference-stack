# 2. SOPS with age, one key per environment

Date: 2026-10-04
Status: accepted

## Context

The repository needs secrets that survive a clone and a CI run without a
secrets manager in the loop for a local demo. Options considered: committed
plaintext behind .gitignore discipline (no), sealed-secrets (cluster-bound,
awkward for Terraform variables), External Secrets Operator with a cloud
backend (right answer in a real account, too much for a laptop), SOPS.

## Decision

SOPS with an age key per environment. `.sops.yaml` binds each file to its key,
so the dev key cannot decrypt prod. CI holds each private key as an
environment-scoped secret, which means the prod key only exists in a job a
reviewer approved.

## Consequences

Key distribution is now a real task: three keys, held by people and by GitHub
environments, with no rotation automation. That is acceptable for a reference
repo and not acceptable in production, where this should become a secrets
manager issuing short-lived database credentials. Recorded in docs/SECRETS.md
as the intended next step rather than left as a gap.
