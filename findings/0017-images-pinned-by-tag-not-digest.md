# 0017. Container images are pinned by tag, not digest

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-829 (inclusion of functionality from untrusted control sphere)
- **Severity:** Low. A version tag is far better than `latest`, but it is still mutable on the registry.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`helm/paymentsvc/values.yaml:7-10` references
`nginxinc/nginx-unprivileged:1.27.2-alpine` and
`helm/paymentsvc/templates/tests/test-connection.yaml:15` references
`curlimages/curl:8.10.1`. Both are Docker Hub tags with no `@sha256:`
digest. Whoever controls the tag controls what runs. The chart helper and
the Rego rule reject `latest` only.

Related, already acknowledged: `docs/THREAT_MODEL.md:20-21` lists the
absence of image signing and provenance as a known weakness.

## How it got here

Generation default. Pinning to a version tag is the common convention and
is what the repo's own guardrails were written to enforce.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
