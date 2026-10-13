# P09: Smoke test and operator scripts (F18, F19)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Implement F18 and F19.

`scripts/smoke-test.sh <env>`: rollout status with a timeout; every
container ready; `helm test`; no password-like key in the ConfigMap;
`runAsNonRoot` held on the Deployment; the `default-deny` NetworkPolicy
present. Exit non-zero on the first failure with a reason.
`scripts/demo-reset.sh`: delete the kind cluster and the Postgres container,
remove state and lockfiles, print the rebuild command.
`Makefile`: targets help, cluster, db, migrate, deploy, plan, smoke, policy,
lint, exercise, spec-check, destroy; every target echoes the command it runs.

Acceptance:
- `bash -n` is clean for every script
- `make help` lists every target with a description
- Against a running cluster and database: `make deploy ENV=dev && make smoke ENV=dev` passes
