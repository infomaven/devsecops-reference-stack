# 0021. `emptyDir` volumes described as bounded have no size limit

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-770 (allocation of resources without limits)
- **Severity:** Low. A container that fills the volume can exhaust node disk and get neighbouring pods evicted.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`helm/paymentsvc/templates/deployment.yaml:58-59` says anything that
writes "needs an explicit, bounded volume". The two volumes at lines
65-68 are `emptyDir: {}` with no `sizeLimit`, and the container has no
`ephemeral-storage` request or limit (`values.yaml:17-23`). They are
bounded only by the node's disk.

## How it got here

Generation default. `emptyDir: {}` is the standard companion to
`readOnlyRootFilesystem`; the comment states the intent and the manifest
does not carry it.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
