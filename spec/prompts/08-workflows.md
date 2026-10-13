# P08: GitHub Actions (F14, F15, F16, F17)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Implement the four workflow features. Pin every action this repository
authors by commit SHA (I10); the vendored template is the reference for how.

`pr-checks.yml` on pull_request: `lint` (terraform fmt, helm lint for all
three values files, yamllint, ansible-lint); `iac-security` (checkov at a
pinned version, installed by pipx, no `@master` action tags); `policy`
(render all three environments and conftest them); `plan` matrix over the
three environments, needing the others, running validate, plan to a file,
plan-JSON policy, and a plan comment on the pull request. Read-only token
except pull-requests: write for the comment.

`apply.yml` as `workflow_call` with an `environment` input: checkout,
terraform setup, decrypt the environment's SOPS file into `GITHUB_ENV`,
apply with the image tag from the commit SHA, smoke test, `helm rollback` on
failure, deployment record. `promote.yml` on push to main: dev, then staging
needing dev, then prod needing staging, each calling `apply.yml`.
`scheduled-drift.yml`: weekday schedule, `plan -detailed-exitcode` per
environment, open an issue on drift.

`security-scan.yml`: copy the toolkit template unmodified with a two-line
provenance header; add it to `.yamllint` ignore (C5).

Acceptance:
- `yamllint -s .` passes
- `grep -c "uses: .*@[0-9a-f]\{40\}" .github/workflows/pr-checks.yml .github/workflows/apply.yml` is nonzero and `grep -c "@master\|@main\|@v[0-9]" ` on the same files, excluding the vendored template, is 0
- Pushed to a GitHub repository with the three environments configured:
  a pull request shows three plan comments; a merge applies dev and waits
  for review on staging
