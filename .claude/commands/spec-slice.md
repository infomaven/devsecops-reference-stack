---
description: Implement or modify one feature from spec/FEATURES.md, spec first, with acceptance checks and REVIEW_NOTES kept in step
argument-hint: <feature ID, e.g. F10a>
---

You are working on feature $ARGUMENTS of `devsecops-reference-stack` under
its change protocol (`spec/CHANGE-PROTOCOL.md`).

1. Read `spec/SPEC.md`, then the row for $ARGUMENTS in `spec/FEATURES.md`
   (the Features table or the Planned changes table). If the row does not
   exist, stop and ask for it; do not invent a feature.
2. Read every file the row names before editing any of them. Read
   `docs/REVIEW_NOTES.md` if the change closes an item there.
3. State, in two sentences, what will change and which invariants in
   SPEC.md are touched. Wait for confirmation.
4. Make the change. Stay inside the files the row names; if another file
   must change, say so and update the row first.
5. Run the feature's acceptance checks, then `make spec-check`, `make lint`,
   and `make policy`. Paste the results.
6. If a recorded decision changed, write a superseding ADR in `docs/adr/`.
7. Update `docs/REVIEW_NOTES.md` and the FEATURES.md row (status, files).
8. Report: files changed, checks run with results, anything still open.

Never add a claim of capability to any document. Never edit
`.github/workflows/security-scan.yml`; it is vendored.
