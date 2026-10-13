# 0014. Workflow permissions and secret scope are broader than needed

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-272 (least privilege violation), CWE-829 (inclusion of functionality from untrusted control sphere)
- **Severity:** Low. It widens what the higher-severity pipeline findings can reach rather than being exploitable alone. No effect locally.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

- `.github/workflows/promote.yml:26,33,40` call `apply.yml` with
  `secrets: inherit`, which hands every repository and organization
  secret to each apply job. The job uses one, `SOPS_AGE_KEY`.
- `.github/workflows/pr-checks.yml:8-10` grants `pull-requests: write` to
  the whole workflow. Only the comment step in the `plan` job needs it;
  the `lint`, `policy`, and `iac-security` jobs, which process PR
  content, hold it too.
- `pr-checks.yml:36,38` run `pipx run yamllint` and
  `pipx run ansible-lint` with no version, so each run installs whatever
  is current.
- Checkouts at `pr-checks.yml:21,67,95`, `apply.yml:23`, and
  `scheduled-drift.yml:23` leave the token in the git config
  (`persist-credentials` is not set to false).

## How it got here

Generation default. Workflow-level permissions and `secrets: inherit` are
the shortest forms that work.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
