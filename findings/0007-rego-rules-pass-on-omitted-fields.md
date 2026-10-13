# 0007. Rego rules pass when a field is omitted or named differently

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-693 (protection mechanism failure)
- **Severity:** Medium. The gate reads as stricter than it is: the chart is hardened today, but removing a hardening line would not fail the build.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

In `policy/kubernetes/security.rego`:

- Line 24 denies only when `allowPrivilegeEscalation` is explicitly
  `true`. Kubernetes defaults it to true when the field is absent, so
  deleting the line from the chart passes.
- Line 11 matches only an image ending in `:latest`. An image with no tag
  at all, which resolves to latest, passes.
- Line 47 matches only environment variable names containing "password".
  An inline `API_TOKEN` or `SECRET_KEY` passes.
- Nothing checks dropped capabilities, seccomp profile, `privileged`,
  host namespaces, or `hostPath` volumes. Those are enforced only by Pod
  Security Admission at deploy time, not at review time.

## How it got here

Missing guardrail. Each rule was written against the manifest as it is
rendered today, where the fields are present, rather than against the
absent-field case. There are no tests for the policies.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
