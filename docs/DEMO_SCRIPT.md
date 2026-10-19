# Screenshare run order

**Oct 11 note: built in two days, not ten.** Sections 4 and 7 are walkthrough
rather than live, unless Monday went better than planned: SOPS is not set up
(the demo reads the database password from the environment) and the toolkit
loop has not been run. Both are documented designs you can speak to. Say that
once, in the opening, and nobody will ask twice.

Twenty-two minutes if nobody interrupts, which they will. Each block stands on
its own, so you can drop any of them and still land the story. Open with the
provenance sentence, once, and then stop apologizing for it.

**Opening line.** "I built this repo over the last few days to show the whole
pipeline in one place.
The Terraform, CI/CD, scanning and policy patterns are what I have done on
client work. The Helm chart authoring and the Ansible database roles are newer
to me, and this is where I wrote my own."

## 1. Map (1 min)
`tree -L 2`. Say what each directory is for. Do not scroll code yet.

## 2. Ansible with the database (5 min)
- `ansible/site.yml`, then `roles/postgres_server/tasks/main.yml`: server
  settings, two roles, neither of them superuser, `no_log: true` on the ones
  that carry a password.
- `roles/app_database/tasks/main.yml`: databases, extensions, revoking the
  default public-schema grant, default privileges for the read-only role.
- Run it: `make db`. Then run it again. **Point at `changed=0`** and say that
  idempotence is the whole reason this is a playbook rather than a shell
  script.
- `ansible-playbook ansible/site.yml --check --diff` to show the dry run.
- Migrations: `db/migrations/`, the ledger table, the `when:` guard. Mention
  `CREATE INDEX CONCURRENTLY` in V002 and why it matters on a live table.
- `ansible/db_backup.yml`: the restore check. "A backup nobody has restored is
  a hope."

## 3. Helm (4 min)
- `helm/paymentsvc/values.yaml` and the three environment files. The point is
  the delta: a reviewer sees prod differs by replica count, log level, limits,
  and PDB, and nothing else.
- `templates/_helpers.tpl`: the `fail` guard on a floating tag.
- `helm template paymentsvc helm/paymentsvc -f values-prod.yaml | head -60`.
- `helm lint`, then `make policy` so they see the Rego gate catch what the
  template guard would also catch. Two gates, different failure modes.

## 4. Secrets (3 min)
- `.sops.yaml`: one age key per environment, so a dev key cannot open prod.
- `.sops.yaml` and `secrets/README.md` as the design. Say plainly that this
  demo passes the password through the environment and that SOPS is how the
  repo is meant to run; the point is that no secret is in the chart, the
  values files, or a rendered manifest.
- The apply path: decrypt to an environment variable, never to a file.
- gitleaks in `.pre-commit-config.yaml` and in CI as the backstop.
- Say what you would use in a real account: Secrets Manager or Vault with a
  short-lived database credential, and OIDC instead of static cloud keys.

## 5. Terraform promotion (5 min)
- `terraform/envs/`: three thin roots, one module.
- `.github/workflows/pr-checks.yml`: fmt, lint, checkov, trivy, gitleaks,
  conftest, then `plan` for all three environments posted as a PR comment.
- `.github/workflows/promote.yml` and `apply.yml`: dev applies on merge,
  staging and prod wait on a GitHub environment with required reviewers.
  **This is where peer review lives**, not in a convention.
- `scripts/smoke-test.sh`: what gates the next environment.
- The rollback step, and `scheduled-drift.yml` for "is prod still what we think
  it is."
- `.github/CODEOWNERS`: prod state and policy need the security group.

## 6. Kubernetes from scratch (4 min)
Follow `docs/K8S_FROM_SCRATCH.md`. If they want hands-on:
`kind create cluster --config kind/cluster.yaml`, then
`kubectl get pods -n kube-system` and name each component as it comes up.

## 7. Optional, if they bite on AI tooling (3 min)
Open `docs/SECURITY_AUDIT.md` first: it is the whole argument on one page, and
reading from it beats reciting. Then `docs/EXERCISE.md`. This repo was generated, then audited with your own
open-source toolkit: Scenario B, `/security-review` on the whole initial
commit, findings recorded in `findings/`, and the toolkit's CI template
running Gitleaks, Semgrep, Trivy, and an SBOM with every action pinned by
commit SHA. One line on why the two repos are complementary: the toolkit
verifies code and says so; this stack covers design and operations, which the
toolkit's own framework alignment lists as out of scope.

If there is time, render the chart with the WebGoat image and let the policy
gate reject it. The guardrail holding against a workload that wants to break
it is the argument for policy as code, made in one screen.

## If they ask how it was built (2 min)
`spec/SPEC.md`, then `spec/FEATURES.md`, then one numbered prompt. "Spec
first, one slice per prompt, acceptance criteria as commands, a conformance
script, and a change protocol that says the spec moves before the code
does. I extracted this spec from the code after the first build, which is
what I'd do with any inherited system." Then `make spec-check` and point at
the PARTIAL rows: every one maps to a REVIEW_NOTES item.

## Closing (30 sec)
"What I would add next: short-lived database credentials from a secrets
manager, a canary step between staging and prod, and SLO-based alerts rather
than threshold alerts."

## If something breaks
Say what you expected, say what you see, and move to the next block. Then come
back to it at the end if there is time. A clean recovery reads better than a
demo that never fails.
