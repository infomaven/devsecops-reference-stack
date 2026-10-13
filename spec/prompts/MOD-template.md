# MOD: modify one feature

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Feature ID: <F##> (or planned change <F##a>)

Read `spec/SPEC.md`, the row for this feature in `spec/FEATURES.md`, and
`docs/REVIEW_NOTES.md` if the change closes an item there. Read every file
the row names before editing any of them.

Change: <one paragraph: what changes and why, in terms of the acceptance
criteria, not the implementation>

Constraints: every invariant in SPEC.md still holds; no file outside the
feature's list changes unless the row is updated first; no new claim of
capability in any document.

When done:
1. Run the feature's acceptance checks and `make spec-check`, `make lint`,
   `make policy`.
2. If a decision changed, write a superseding ADR.
3. Update `docs/REVIEW_NOTES.md`: remove what this closes, add what it opens.
4. Update the FEATURES.md row: status, files, and the prompt reference.
5. Report: files changed, checks run with results, anything still open.
