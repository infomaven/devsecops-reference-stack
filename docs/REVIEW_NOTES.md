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

## 9. The placeholder service is a placeholder

The chart deploys `nginx-unprivileged` and calls it `paymentsvc`. The
`DB_*` environment variables are set and nothing reads them. The security
context, probes, and policy are real; the application is not. A small real
service that actually opens a database connection would make the smoke test
mean more.

## 10. Smaller things

- `Makefile` sleeps five seconds after starting Postgres instead of waiting
  for readiness. The Ansible `pre_tasks` ping covers it, but the Makefile
  should not depend on that.
- `pr-checks.yml` pins `CHECKOV_VERSION` to a placeholder. It needs a verified
  release before it runs.
- `helm test` proves the service answers, not that it is correct.
- The three age public keys in `.sops.yaml` are placeholders, and SOPS is not
  wired into the local demo at all; the password passes through the shell.
- `verify`-style checks exist for resume data in another project of mine and
  not here: this repo has lint and policy but no test of its own scripts.

## What is deliberately not on this list

Local state, a single kind cluster, and the demo password in the Makefile
are documented demo conveniences, not oversights. They are called out where
they appear.
