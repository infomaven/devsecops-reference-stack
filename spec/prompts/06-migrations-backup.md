# P06: Migrations and backup (F10, F11)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Implement F10 and F11.

`roles/app_database/tasks/apply_migration.yml`, included per database: read
the ledger, apply each `db/migrations/*.sql` not yet recorded in filename
order, and record it. Migrations that cannot run inside a transaction (for
example `CREATE INDEX CONCURRENTLY`) must be applied with autocommit; mark
them by a filename convention or a header comment and branch on it. Record
the ledger row in the same unit of work as the migration where the module
allows it, and document the limitation where it does not.

`db/migrations/`: V001 baseline schema with a `payment` table and a unique
index on `external_ref`; V002 a settlement lookup index built CONCURRENTLY;
V003 an append-only `payment_audit` table. All re-runnable.

`ansible/db_backup.yml`: dump each database, copy dumps out of the
container, restore the dev dump into a scratch database, assert the restored
schema has tables, drop the scratch database, expire dumps older than the
retention period.

Acceptance:
- Against a running Postgres container: `site.yml --tags migrate` applies
  three migrations on the first run and none on the second
- V002 succeeds (the CONCURRENTLY migration is applied outside a transaction)
- `db_backup.yml` prints the restore-check success message
