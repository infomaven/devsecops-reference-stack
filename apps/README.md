# Application profiles

The pipeline deploys the stand-in service (`nginx-unprivileged`, configured in
`helm/paymentsvc/values.yaml`) unless an application profile here is selected.
A profile is a Helm values overlay that names a real application's image and
the few things that differ about it. Terraform layers it after the
environment's values file, so the chart, the Rego policy, the default-deny
network policy, and the smoke test stay the same for every application.

## Selecting an application

```bash
make select-app                                   # asks, step by step
make select-app ARGS="--name orders --image ghcr.io/acme/orders:1.4.2 \
  --port 3000 --health /healthz --writable /tmp"  # a published image
make select-app ARGS="--name orders --source ../orders"   # docker build
make select-app ARGS=--standin                    # back to the stand-in
```

The script writes `apps/<name>.yaml`, renders all three environments with it
and runs `conftest`, and only then records the name in `apps/.selected`
(per machine, not committed). `make plan`, `make deploy`, `make policy`, and
`make destroy` read that file; `APP=<name>` on the command line overrides it,
and `APP=` forces the stand-in for one command.

With `--source`, the image is built as `local/<name>:<short commit SHA>`
(`-dirty` when the tree has uncommitted changes) and loaded into the kind
cluster with `kind load docker-image`. Select after `make cluster`, or run the
printed `kind load` command once the cluster exists.

## What the application has to accept

The stand-in's hardening applies unchanged. A profile cannot relax it (I13),
and the policy check fails the selection if the rendered result does.

- Runs as a non-root numeric user ID (`--uid`, default 10001), with every
  capability dropped and no privilege escalation.
- Listens on a port of 1024 or higher.
- Writes only to the directories listed in `--writable`; the root filesystem
  is read-only and each listed path gets an `emptyDir`.
- Answers HTTP 2xx on the `--health` path; liveness, readiness, and
  `helm test` all use it.
- Uses at most the memory limits in `values-<env>.yaml`. Edit the profile to
  add a `resources:` block if it needs more.
- Reaches nothing but DNS and the database port. The network policy is
  default-deny, so calls to other services or the internet fail.
- Reads its database settings from `DB_HOST`, `DB_PORT`, `DB_NAME`,
  `DB_USER`, and `DB_PASSWORD` (from the `paymentsvc-db` Secret), or ignores
  them.

The release, namespace, and Kubernetes object names stay `paymentsvc` for
every application, so the smoke test and the workflows do not need to know
which one is deployed.
