# 4. Promotion by merge, with environment gates in CI

Date: 2026-10-04
Status: accepted

## Context

"Deploy to prod" has to be answerable afterwards: which commit, who approved,
what did the plan say. Options: long-lived branches per environment (merge
conflicts become deployment risk), Terraform workspaces (one state, one blast
radius), or separate state per environment promoted from one branch.

## Decision

One module, three thin roots, one state each, promoted from `main` in order:
dev on merge, then staging and prod behind GitHub environment reviewers. The
pull request carries a plan comment for all three environments, so the prod
diff is visible before the merge, not after.

## Consequences

Three applies per merge, which is slower than a single environment and is the
point: the pipeline stops at the first smoke test that fails. Environment
gates mean a reviewer must be available; for an urgent fix that is a known cost
and the alternative is an unreviewed prod apply. Workspaces would have been
less code and a worse blast radius.
