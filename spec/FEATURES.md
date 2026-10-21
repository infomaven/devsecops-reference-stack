# FEATURES

One row per feature. Acceptance criteria are checkable; `scripts/spec-check.sh`
runs the mechanical ones. "Prompt" is the numbered prompt in `prompts/` that
produces or modifies the feature. Status: done, partial, or planned.

| ID | Feature | Acceptance criteria | Files | Prompt | Status |
|---|---|---|---|---|---|
| F01 | Local cluster | `kind/cluster.yaml` defines one control plane and two workers; port 8080 mapped; CNI flag documented for the from-scratch walkthrough | `kind/cluster.yaml` | P01 | done |
| F02 | Hardened chart defaults | `values.yaml` sets runAsNonRoot, drop ALL, no privilege escalation, read-only root, resource limits, probes; environments override only deltas | `helm/paymentsvc/values*.yaml` | P02 | done |
| F03 | Chart guardrail | `_helpers.tpl` fails the render on `image.tag` of `latest` or empty (I1) | `helm/paymentsvc/templates/_helpers.tpl` | P02 | done |
| F04 | Workload templates | Deployment, Service, ConfigMap, NetworkPolicy, PDB, NOTES, test hook; config checksum annotation rolls pods on change | `helm/paymentsvc/templates/*` | P02 | done |
| F05 | Terraform module | Namespace with labels and restricted PSA, default-deny NetworkPolicy, Kubernetes Secret from a sensitive variable, atomic `helm_release`; input validation on environment and image tag | `terraform/modules/app/*` | P03 | done |
| F06 | Thin environment roots | dev, staging, prod roots contain provider, variables, one module call; no resources (I4) | `terraform/envs/*/main.tf` | P03 | done |
| F07 | Secrets design | `.sops.yaml` maps each environment file to its own age key; chart references `database.existingSecret` by name; README explains the decrypt-to-env path (I3) | `.sops.yaml`, `secrets/README.md`, `docs/SECRETS.md` | P04 | partial: keys are placeholders; local demo passes the value through the shell |
| F08 | Postgres server role | Server settings applied and reloaded; application and read-only roles created NOSUPERUSER with `no_log` (I7, I8) | `ansible/roles/postgres_server/*` | P05 | done |
| F09 | Application database role | Databases, extensions, revoked public grants, default read-only privileges | `ansible/roles/app_database/tasks/main.yml` | P05 | partial: only the first extension installs (REVIEW_NOTES 3) |
| F10 | Migrations with ledger | SQL files applied in filename order; `schema_migrations` records each; re-run applies nothing (I9) | `ansible/roles/app_database/tasks/apply_migration.yml`, `db/migrations/*` | P06 | partial: CONCURRENTLY inside a transaction (REVIEW_NOTES 1); ledger not atomic (2) |
| F11 | Backup with restore check | Dumps each database, restores one into a scratch database, asserts tables exist, expires old dumps | `ansible/db_backup.yml` | P06 | done |
| F12 | Policy: manifests | Rego denies floating tags, root, privilege escalation, writable root, missing memory limits, inline password env, missing ownership label (I2, I3) | `policy/kubernetes/security.rego` | P07 | done |
| F13 | Policy: plans | Rego denies namespaces missing required labels and any plan that deletes a namespace | `policy/terraform/plan.rego` | P07 | done |
| F14 | PR checks | lint, iac-security (pinned), policy on all three renders, plan matrix with plan comment and plan-JSON policy | `.github/workflows/pr-checks.yml` | P08 | done |
| F15 | Promotion with gates | dev on merge; staging and prod via reusable apply workflow inside GitHub environments; smoke test; rollback on failure; deployment record (I5, I6) | `.github/workflows/promote.yml`, `apply.yml` | P08 | partial: rollback leaves Terraform state stale (REVIEW_NOTES 5); OIDC declared, unused (7) |
| F16 | Drift detection | Nightly `plan -detailed-exitcode` per environment; opens an issue on drift | `.github/workflows/scheduled-drift.yml` | P08 | partial: no dedupe (REVIEW_NOTES 8) |
| F17 | Vendored scanning | Toolkit's `security-scan.yml` copied unmodified; excluded from this repo's yamllint (C5) | `.github/workflows/security-scan.yml`, `.yamllint` | P08 | done |
| F18 | Smoke test | Rollout complete, all containers ready, `helm test`, no password key in the ConfigMap, runAsNonRoot held, default-deny policy present | `scripts/smoke-test.sh` | P09 | done |
| F19 | Operator scripts and Makefile | bootstrap preflight, demo reset, Makefile targets that echo their commands | `scripts/*.sh`, `Makefile` | P09 | done |
| F20 | Decision records | ADRs for records, SOPS, Helm over manifests, promotion model (I12) | `docs/adr/*` | P10 | done |
| F21 | Threat model and monitoring | STRIDE table with mitigations and stated weaknesses; monitoring doc with the three deploy questions and testing by layer | `docs/THREAT_MODEL.md`, `docs/MONITORING.md` | P10 | done |
| F22 | Audit loop | EXERCISE.md loop, findings directory with template, `make exercise`, SECURITY_AUDIT.md | `docs/EXERCISE.md`, `findings/*`, `docs/SECURITY_AUDIT.md` | P11 | partial: no findings recorded yet |
| F23 | Review notes | Known weaknesses in priority order with reasons | `docs/REVIEW_NOTES.md` | P12 | done |
| F24 | Spec layer | SPEC, FEATURES, prompts, change protocol, conformance script, Claude Code commands | `spec/*`, `scripts/spec-check.sh`, `.claude/commands/*` | P00 | done |
| F25 | Target application selection | `scripts/select-app.sh` writes `apps/<name>.yaml` from an image reference or a local Dockerfile, refuses a floating or empty tag and a port below 1024, and records the choice in `apps/.selected`; `--standin` clears it; profiles never set I2's security switches (I13); `make plan`, `deploy`, and `policy` layer the selected profile after the environment values; the Terraform module takes `app_values_file` and applies `image_tag` only when set; the chart's writable volumes and test-hook path come from values | `scripts/select-app.sh`, `apps/*`, `Makefile`, `helm/paymentsvc/values.yaml`, `helm/paymentsvc/templates/deployment.yaml`, `helm/paymentsvc/templates/tests/test-connection.yaml`, `terraform/modules/app/*`, `terraform/envs/*/main.tf` | MOD | partial: CI builds and promotes only the image tag, not a selected profile (REVIEW_NOTES 9) |

## Planned changes, from REVIEW_NOTES

| ID | Change | Replaces | Prompt |
|---|---|---|---|
| F10a | Mark migrations needing autocommit and apply them outside a transaction; write the ledger row in the same unit | F10 partial | MOD |
| F09a | Install every extension in the list with `subelements` | F09 partial | MOD |
| F15a | Roll back through Terraform (previous image tag) so state and cluster agree | F15 partial | MOD |
| F16a | Dedupe drift issues by label | F16 partial | MOD |
| F04a | Pin NetworkPolicy egress to the database destination by ipBlock | F04 | MOD |
