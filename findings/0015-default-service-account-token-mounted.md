# 0015. The default service account token is mounted in the pod

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-250 (execution with unnecessary privileges)
- **Severity:** Low. The default service account has no RBAC bindings here, so the token grants little; it is still a credential the workload never uses.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`helm/paymentsvc/templates/deployment.yaml:21-23` sets a pod security
context and no `serviceAccountName` or `automountServiceAccountToken`.
The chart has no ServiceAccount template. The pod therefore runs as the
namespace's `default` service account with its API token mounted. A
compromised container gets an authenticated identity to the API server,
and any permission later bound to `default` in that namespace reaches it
automatically.

The Rego policy does not check for this.

## How it got here

Generation default. The chart was hand-written without the ServiceAccount
template that `helm create` includes, and the Kubernetes default is to
mount the token.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
