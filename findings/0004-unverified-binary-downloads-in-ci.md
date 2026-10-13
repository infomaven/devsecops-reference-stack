# 0004. Binaries downloaded and installed in CI with no checksum

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-494 (download of code without integrity check)
- **Severity:** High in the system this models: the sops download runs in the step that holds the prod decryption key. No effect locally.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

- `.github/workflows/apply.yml:33-34` downloads `sops` with `curl -sSL`
  (no `-f`, no checksum) and installs it with `sudo mv`. The same step has
  `SOPS_AGE_KEY` in its environment (line 31) and runs the binary two
  lines later.
- `.github/workflows/pr-checks.yml:73-75` and `112-114` download and
  install `conftest` the same way.

A replaced release asset would run with the age private key for whichever
environment is being applied, including prod.

## How it got here

Copied pattern. `security-scan.yml` in the same directory shows the
verified form (pinned version plus `sha256sum --check --strict`); the
hand-written workflows did not follow it.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
