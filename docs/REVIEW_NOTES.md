# Review notes: what I would fix next, and why

A reviewer reading this repository should find these before I point them
out, so I am pointing them out. Each one is a real weakness in the code as
written, not a hypothetical. The order is by how much I would want it fixed
before this ran anywhere real.

## 1. `CREATE INDEX CONCURRENTLY` inside a transaction

`db/migrations/V002__settlement_lookup_index.sql` builds its index
`CONCURRENTLY`, which Postgres refuses inside a transaction block. The
Ansible role applies migrations with `community.postgresql.postgresql_script`,
which runs the file as one unit, so this migration will fail on a real run
unless the module is set to autocommit. The right fix is to mark migrations
that need autocommit and apply them outside a transaction, or to move
migrations to a tool that already handles this (Flyway, which I have used,
does). The lesson is older than this repo: a migration runner has to know
which statements are transactional.

## 2. The migration ledger is not atomic with the migration

`apply_migration.yml` applies a file in one task and records it in
`schema_migrations` in the next. If the second task fails, the migration has
run and the ledger does not know, and the next run applies it again. V001
and V003 are written `IF NOT EXISTS` so they survive that, but that is luck
in the SQL, not safety in the runner. Record the ledger row in the same
transaction as the migration, or use a runner that does.

## 3. Only the first extension is installed

`roles/app_database/tasks/main.yml` enables
`{{ item.extensions | first }}`. The data structure allows a list; the task
honors one element. A `subelements` loop fixes it. I left it because the
demo needs one extension, which is exactly how shortcuts become bugs.

## 4. The database password is in Terraform state

`kubernetes_secret.db` takes the password as a `sensitive` variable, which
keeps it out of plan output and logs, but Terraform state stores it in
plaintext. With local state for the demo, that is a file on disk. In a real
account: an encrypted, versioned, access-controlled backend at minimum, and
better, have the application read a short-lived credential from a secrets
manager so Terraform never holds it at all.

## 5. Rollback and state disagree

`apply.yml` rolls back with `helm rollback` when the smoke test fails.
Terraform still believes the new image tag is deployed. The next plan would
try to re-apply it. The cleaner path is to roll back through Terraform
(re-apply the previous tag), or to let Helm own the release entirely and keep
Terraform to the namespace and policy.

## 6. The network policy's egress is wider than it looks

The chart's `NetworkPolicy` allows egress to the database port on any
destination. It should name the database by `ipBlock` or by namespace and
pod selector. On kind, with the database outside the cluster, that means an
`ipBlock` for the host.

## 7. The workflows declare OIDC and never use it

`promote.yml` and `apply.yml` request `id-token: write`, which is the right
shape for assuming a cloud role without stored keys, and then talk to a local
kubeconfig because the demo runs on kind. The intent is documented; the
implementation is not there. Against a real account, the apply job needs the
`configure-aws-credentials` step with a role per environment.

## 8. Drift detection would spam issues

`scheduled-drift.yml` opens a new issue every night for every drifted
environment. After a week that is five issues about the same thing. Dedupe by
label: search for an open issue first and comment on it instead.

## 9. The placeholder service is a placeholder, unless one is selected

By default the chart deploys `nginx-unprivileged` and calls it `paymentsvc`.
The `DB_*` environment variables are set and nothing reads them. The
security context, probes, and policy are real; the application is not.

`make select-app` (F26) now points the local pipeline at a real application
through a profile in `apps/`, and holds it to the same policy, network
policy, and smoke test. What that leaves open:

- CI does not know about profiles. The workflows pass `image_tag` only, so a
  merge promotes the stand-in's image with a new tag; a profile has to be
  committed and passed as `app_values_file` in `apply.yml` before CI deploys
  the selected application. The `.github/` workflows are not in this working
  tree, so that change waits for them.
- `--source` runs `docker build` on whatever directory it is given, on the
  operator's machine, outside the toolkit's sandbox. Build untrusted code in
  the sandbox first.
- The contract a real application must meet (non-root numeric UID, port
  1024 and up, listed writable paths, `DB_*` names, egress to DNS and the
  database only) is enforced at render and at run time, but a mismatch shows
  up as a failed rollout, not as a message saying which rule it broke.
- Object names stay `paymentsvc` whatever runs, so the smoke test does not
  change; the cost is that `kubectl get` does not say which application it is.

The same gap shows in the promotion workflow. No image is built, so
`apply.yml` deploys the pinned stand-in tag from the environment root, not
a tag derived from the commit, to a kind cluster the job creates and
discards. With no encrypted secret file and no age key configured, it uses
a throwaway database password and says so in the run. The ordering, the
smoke test and the environment gates are exercised; a build, a real secret
and a cluster that outlives the job are not.

## 10. Smaller things

- `Makefile` sleeps five seconds after starting Postgres instead of waiting
  for readiness. The Ansible `pre_tasks` ping covers it, but the Makefile
  should not depend on that.
- The Python tools (ansible-core, ansible-lint, yamllint, psycopg2) are
  whatever the operator has installed into their system Python, unpinned.
  `bootstrap.sh` checks they exist, not which version, and nothing installs
  the linters `make lint` needs. Planned as F19a: a pinned `requirements.txt`
  and a project venv. The other tools are native binaries and stay on the
  host.
- `pr-checks.yml` pins `CHECKOV_VERSION` to a placeholder. It needs a verified
  release before it runs.
- `helm test` proves the service answers, not that it is correct.
- The three age public keys in `.sops.yaml` are placeholders, and SOPS is not
  wired into the local demo at all; the password passes through the shell.
- `verify`-style checks exist for resume data in another project of mine and
  not here: this repo has lint and policy but no test of its own scripts.

## 11. Invariant I10 is stated, mistested, and violated

Found last, after the list was numbered. On severity it belongs around 4:
CI holds the credentials that can tamper with an artifact after every gate
has passed it.

**The state.** Across the four workflows this repository authors, fourteen
external action references: one pinned by commit SHA
(`pr-checks.yml:50`), thirteen on `@v4` and `@v3`. Three further `uses:`
lines point at local reusable workflows and correctly need no pin. The
vendored `security-scan.yml` pins all eleven of its own.

**Why it matters.** A tag is a mutable pointer. The action owner, or anyone
who takes their account, can move it, and the moved tag produces no diff in
this repository: nothing to review, nothing in `git log`. The action runs
inside the job with its token, its OIDC identity and its filesystem. In
March 2025 `tj-actions/changed-files` had existing version tags repointed at
a commit that read secrets out of the runner's process memory and printed
them to the logs; repositories pinned by SHA were unaffected
(CVE-2025-30066).

**It failed in three layers, and the middle one is the lesson.**

1. *Stated.* `spec/SPEC.md` I10 says every action this repository authors is
   pinned by commit SHA. `docs/SECURITY_AUDIT_OVERVIEW.md` (then `TWO_REPOS.md`) went further and claimed it was
   already done; that sentence has been corrected to say what is true. The
   comment at `pr-checks.yml:48` states the reasoning correctly, directly
   above the one line that follows it.
2. *Tested.* `spec-check.sh` F14 asserted `! grep "uses: .*@master"`, which
   forbids `@master` and permits `@v4`. It ran, it passed, and it tested a
   weaker condition than the invariant it appeared to cover. A check that
   reports green on an adjacent condition is worse than no check: it
   consumes the attention that would have found the gap. More broadly,
   `spec-check.sh` mapped every feature ID to a test and no invariant to
   anything at all.
3. *Deployed.* Thirteen references drifted, which is the resting state: the
   platform's own documentation examples use `@v4`, so every copy-paste
   produces a violation. A control that fights the default needs
   enforcement, not intention.

**The fix, in increasing order of value.**

- Pin the thirteen references, as in the workaround below. Dependabot
  updates SHA-pinned actions and keeps the version comment current, so this
  does not freeze them.
- Test the invariant rather than a proxy. `spec-check.sh` now counts
  unpinned external references on every run and reports I10 as partial with
  the live count, so the number falls as references are pinned and the line
  turns green by itself at zero.
- Make an untested invariant a reported gap, then a failing one.
  `spec-check.sh` already failed on a feature ID with no test; it now lists
  invariants with no mechanical test. Promoting that list from a report to a
  failure is the change that closes the class rather than this instance, and
  it is one line.

**The workaround.** Pin each reference to the full 40-character SHA that the
tag points at today, and keep the version as a comment:

```bash
# Resolve a tag to its commit SHA (follows annotated tags)
gh api repos/actions/checkout/commits/v4.2.2 --jq .sha
```

```yaml
# before
- uses: actions/checkout@v4
# after: the SHA printed above, with the version kept as a comment
- uses: actions/checkout@<40-character-sha>  # v4.2.2
```

Then add `.github/dependabot.yml` with a `github-actions` entry. Dependabot
opens pull requests that move the SHA and update the version comment
together, so pinned actions still get updates, now through review. To stop
new tag references from getting in, turn on GitHub's "Require actions to be
pinned to a full-length commit SHA" policy under Settings > Actions >
General. `make spec-check` reports the number of unpinned references on its
I10 line, and that line passes once the count reaches zero.

## 12. IaC vetting reports more than it blocks

`iac-vetting.yml` blocks on formatting, validation, schema errors,
actionlint and the Kubescape floors. Everything else it finds is report-only
until the repository variable `IAC_VETTING_BLOCKING` is set, because the
scanners still return:

- **Checkov, 12 failed checks on the chart.** It was 26 until the Helm test
  pod was hardened. What is left: the default namespace, an artifact of
  Checkov rendering the chart with no release namespace; tag rather than
  digest (`findings/0017`) and the pull policy on both pods; and on the
  Deployment the service account token (`0015`) and the password as an
  environment variable.
- **zizmor, 32 findings in the four older workflows.** Unpinned actions
  (item 11, `0003`), input interpolated into shell (`0022`), broad
  permissions and inherited secrets (`0014`). None in `iac-vetting.yml`.
- **tflint, 3 warnings.** `terraform/modules/app` declares no
  `required_version` and no `required_providers`.
- **Kubescape, 92.5 on NSA and 100 on MITRE** for every environment. The
  floors are 90 and 100: they stop a regression, they do not certify the
  chart.

Two limits of the workflow itself:

- Checkov has one applicable check for this Terraform and none for these
  Ansible roles. The Kubernetes and Helm providers are thinly covered, so
  the Rego plan policy in `pr-checks.yml` is still the real Terraform gate.
- `pr-checks.yml` still runs its own, older Checkov on Terraform only. The
  two overlap until that job is retired.

The fix is the findings, not the switch: close them, raise the floors, then
set `IAC_VETTING_BLOCKING`.

## What is deliberately not on this list

Local state, a single kind cluster, and the demo password in the Makefile
are documented demo conveniences, not oversights. They are called out where
they appear.
