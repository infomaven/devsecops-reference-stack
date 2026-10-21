# P02: Helm chart (F02, F03, F04)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Implement F02, F03, F04 under `helm/paymentsvc/`.

Constraints from SPEC: invariants I1, I2, I3. The chart never holds a secret
value; it references `database.existingSecret` by name. Defaults are the
restrictive case: runAsNonRoot with a fixed uid, seccomp RuntimeDefault,
allowPrivilegeEscalation false, readOnlyRootFilesystem true with an emptyDir
per entry in `writablePaths` (the stand-in lists /tmp and the nginx cache;
an application profile from F25 lists its own), capabilities drop ALL, resource
requests and limits, liveness and readiness probes.

Files: `Chart.yaml`; `values.yaml`; `values-dev.yaml`, `values-staging.yaml`,
`values-prod.yaml` carrying only deltas (replicas, log level, limits, PDB);
`templates/_helpers.tpl` with name helpers, standard labels, and an image
helper that calls `fail` on an empty or `latest` tag; `templates/deployment.yaml`
with a `checksum/config` annotation over the ConfigMap; `service.yaml`;
`configmap.yaml`; `networkpolicy.yaml` allowing ingress on the service port
from the namespace and egress only to DNS and the database port; `pdb.yaml`
gated on `podDisruptionBudget.enabled`; `NOTES.txt`; `tests/test-connection.yaml`
as a helm test hook using curl.

Acceptance:
- `helm lint helm/paymentsvc -f helm/paymentsvc/values-<env>.yaml` passes for all three
- `helm template x helm/paymentsvc --set image.tag=latest` fails with the
  guard message
- `helm template x helm/paymentsvc -f helm/paymentsvc/values-prod.yaml | conftest test --policy policy/kubernetes -`
  passes once P07 exists
