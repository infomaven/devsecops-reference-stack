# 0016. The prod SOPS rule encrypts only two named keys

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-312 (cleartext storage of sensitive information)
- **Severity:** Low today, because no encrypted files exist yet. In the system this models, the next secret added to prod under a new name is committed in plaintext.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`.sops.yaml:11` sets `encrypted_regex: "^(db_password|api_token)$"` on
the prod rule only. SOPS then encrypts those two keys and leaves every
other value in `secrets/prod.enc.yaml` readable. A new key such as
`webhook_secret` would be stored in the clear, in a file whose name says
it is encrypted, with no error from SOPS. The dev and staging rules have
no regex and encrypt every value.

`docs/SECRETS.md:19` describes this as keeping "structure readable while
values stay sealed", which SOPS already does without the regex: keys are
never encrypted, only values.

## How it got here

Deliberate tradeoff that was never revisited. The regex was added for
reviewability; it turns an encrypt-everything default into an allowlist
that has to be maintained by hand, on the environment where a miss costs
most.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
