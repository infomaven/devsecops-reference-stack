# P12: Review notes (F23)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Review the repository as its harshest competent reader and write
`docs/REVIEW_NOTES.md`: every real weakness in the code as written, in
priority order, each with what it is, why it matters, and the fix. Separate
deliberate demo conveniences from oversights. Then update `spec/FEATURES.md`:
mark affected features partial, and add a planned-change row for each
weakness that will be fixed.

Acceptance:
- Every item in REVIEW_NOTES.md is referenced from FEATURES.md as either a
  partial status or a planned change
- `make spec-check` reports PARTIAL for exactly the features REVIEW_NOTES
  names
