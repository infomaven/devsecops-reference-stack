---
description: Run the conformance script and explain any drift between the repository and spec/FEATURES.md
---

Run `bash scripts/spec-check.sh` from the repository root and read its output.

For every FAIL: name the feature, open the files its row in
`spec/FEATURES.md` lists, and say whether the spec is wrong, the code is
wrong, or the check is wrong. Do not fix anything yet.

For every PARTIAL: confirm the reason still matches `docs/REVIEW_NOTES.md`.
If a REVIEW_NOTES item has been fixed but the check still says PARTIAL, the
check in `scripts/spec-check.sh` needs its known-partial flag cleared; say
so.

End with a three-line summary: pass/partial/fail counts, the one FAIL that
should be fixed first and why, and whether the spec itself needs a change.
