# 0006. The Helm test pod bypasses the policy gate and conflicts with the cluster's controls

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-693 (protection mechanism failure)
- **Severity:** Medium. The policy gate covers one workload kind, so anything else ships unchecked. Locally it is also a likely demo failure.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`helm/paymentsvc/templates/tests/test-connection.yaml:13-21` defines a
bare `Pod` with no security context and no resource limits. Every rule in
`policy/kubernetes/security.rego` starts with `input.kind == "Deployment"`,
so the pod passes CI untouched. The same gap would let a Job, CronJob,
StatefulSet, or DaemonSet through.

Two runtime consequences, reasoned from the code and not run:

- The namespace enforces the `restricted` Pod Security level
  (`terraform/modules/app/main.tf:11`). The pod sets none of the fields
  that level requires, so admission should reject it.
- The pod carries the chart's selector labels (via `paymentsvc.labels`),
  so the chart NetworkPolicy applies to it. That policy allows egress to
  DNS and the database port only, not to the service on 8080.

`scripts/smoke-test.sh:23` runs `helm test`, so `make smoke` is likely to
fail, and in CI that failure triggers the rollback step.

## How it got here

Generation default. The test pod is standard `helm create` boilerplate,
and the hardening was applied to the Deployment and the policy written to
match it.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
