# 0005. Promotion can be dispatched from any branch

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-284 (improper access control); OWASP CICD-SEC-1, insufficient flow control
- **Severity:** High in the system this models: unreviewed code reaches dev with no gate and can reach prod on a deployment approval alone. No effect locally.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`.github/workflows/promote.yml:11` adds `workflow_dispatch` with no branch
condition. A manual run from any branch makes `apply.yml` check out that
branch and apply it to dev, which has no required reviewers
(`apply.yml:19-20`). Staging and prod then wait for an environment
approval, but the approver is approving a deployment, not a reviewed pull
request.

`docs/THREAT_MODEL.md:7` states that "applies run only from `main`". The
workflow does not enforce that.

Not verified: whether the GitHub environments restrict deployment
branches. That is repository configuration, not code in this tree.

## How it got here

Generation default. `workflow_dispatch` is routinely added alongside
`push` for convenience, and the threat model was written against the
intended flow rather than the trigger list.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
