# Target context

Intake recorded 2026-10-12 via `/setup-target` (security-engineer-toolkit).
Later sessions and toolkit commands should read this instead of re-asking.
Update it if any answer changes.

## Target

`/Users/nadine/DEV/DevSecOps/bimodal-interview-prep-v2.3/devsecops-reference-stack`

## Stack

Stated by the owner and confirmed by a read-only look at the tree:

- Terraform: `terraform/envs/{dev,staging,prod}`, `kubernetes` and `helm`
  providers only, `local` backend
- Helm: `helm/paymentsvc`
- Ansible: `ansible/`
- Shell: `scripts/`, plus a `Makefile`
- Also present: OPA/Rego (`policy/`), SOPS (`.sops.yaml`, `secrets/`),
  SQL (`db/`), kind cluster config (`kind/`), pre-commit, yamllint

## Risk profile

- Local demo with fake data only
- Not internet-facing; runs against a local kind cluster, no cloud account
- Single-tenant
- No payments, health, or other regulated personal data (the demo is
  payments-themed, `paymentsvc`, but the data is fake)
- No compliance target

**Prioritisation consequence:** rank findings by actual risk (local, fake
data), and note separately where a defect would be severe in the real
payments system the demo models.

## Authorization

Owner's own code.

## Findings tracking

Markdown log in the project. A `findings/` directory already exists; use
it rather than creating a second location.

## Effort budget

Solo. A few hours in total, not recurring. The stack is being shown on
2026-10-13, so this is a single triage pass, not a program: no recurring
cadence or long-horizon milestones from `OPERATING-MODEL.md`.

## CI integration

No running pipeline. Five GitHub Actions workflows are defined in
`.github/workflows/` (`pr-checks`, `security-scan`, `apply`, `promote`,
`scheduled-drift`), but the directory is not a git repository and has no
remote, so nothing executes them. Prevent phase is deferred; the workflow
files are still in scope for review as code.
