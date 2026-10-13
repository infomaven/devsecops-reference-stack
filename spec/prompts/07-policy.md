# P07: Policy as code (F12, F13)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Implement F12 and F13 in Rego v1 syntax (`import rego.v1`, `deny contains msg if`).

`policy/kubernetes/security.rego`, run against rendered manifests: deny
Deployments whose containers use a `:latest` tag; deny missing
`runAsNonRoot`; deny `allowPrivilegeEscalation: true`; deny missing
`readOnlyRootFilesystem`; deny missing memory limits; deny any env var whose
name contains "password" set inline rather than via `valueFrom`; deny
Deployments missing `app.kubernetes.io/part-of`. Warn on a single replica.

`policy/terraform/plan.rego`, run against `terraform show -json`: deny
namespaces missing `owner`, `cost-center`, `managed-by` labels; deny any
plan that deletes a namespace.

Add `make policy` to render each environment and pipe it through conftest.

Acceptance:
- `make policy` passes for dev, staging, prod
- `helm template x helm/paymentsvc --set image.tag=latest ...` is refused by
  the template; a manifest with an inline `DB_PASSWORD: x` env var is denied
  by conftest
