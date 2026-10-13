# 0008. Decrypted password written to `GITHUB_ENV`

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-532 (sensitive information in log file), CWE-200 (exposure of sensitive information)
- **Severity:** Medium in the system this models: the prod database password is visible to every later step and is not masked in logs. No effect locally.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`.github/workflows/apply.yml:36-37` appends
`TF_VAR_db_password=<decrypted value>` to `$GITHUB_ENV`. Three things
follow:

- Every later step in the job inherits it, including
  `scripts/smoke-test.sh`, the `helm rollback`, and the logging step,
  none of which need it.
- The value comes out of `sops`, not out of `secrets.*`, so GitHub does
  not know to mask it. There is no `::add-mask::`.
- A password containing a newline would write extra lines into
  `GITHUB_ENV`, setting arbitrary environment variables for later steps.

The comment on line 35 ("never to a file in the workspace") is true, and
`docs/SECRETS.md` rule 4 permits an environment variable for the life of
a job. The scope is wider than the one step that needs it.

## How it got here

Copied pattern. Writing to `GITHUB_ENV` is the usual way to pass a value
between steps; the decrypt and the apply were split into two steps.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
