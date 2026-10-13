# 0002. Pull-request code runs `terraform plan` with the database secret

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-829 (inclusion of functionality from untrusted control sphere); OWASP CICD-SEC-4, poisoned pipeline execution
- **Severity:** High in the system this models: an unmerged branch reaches the prod database password. No effect locally, because the workflows cannot run (no git repository, no remote).
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

The `plan` job in `.github/workflows/pr-checks.yml:85-109` runs on
`pull_request`, checks out the PR's code, and runs `terraform init` and
`terraform plan` for dev, staging, and prod with
`TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}` in the environment.
`terraform plan` executes whatever providers and data sources the PR
declares, so a same-repo branch can read the secret before anyone has
reviewed it. Fork PRs do not receive secrets; branches in the repository
do.

Not verified: whether the `dev-plan`, `staging-plan`, and `prod-plan`
GitHub environments (line 93) have required reviewers. That is repository
configuration, not code in this tree.

## How it got here

Copied pattern. "Plan on every PR and comment the result" is the standard
Terraform workflow shape; it is safe only when the plan needs no secret
or the job is gated.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
