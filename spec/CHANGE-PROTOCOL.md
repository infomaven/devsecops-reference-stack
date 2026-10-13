# Change protocol

The spec was extracted from the code on Oct 11, 2026, after the first build.
That is the honest order of events, and it is also how any inherited
codebase gets a spec: read the code, write down what it does and why, then
make the code answer to the document from that point on.

## To modify the repository

1. Edit the spec first. Change or add the row in `FEATURES.md`; add or amend
   an invariant in `SPEC.md` if one is affected. If the change reverses a
   recorded decision, write a new ADR that supersedes the old one.
2. Run the slice. Use `prompts/MOD-template.md` with the feature ID, or the
   numbered prompt that owns the feature if it is a rebuild of that slice.
   In Claude Code, `/spec-slice F10a` does the same thing.
3. Check conformance. `make spec-check`, then `make lint` and `make policy`.
   In Claude Code, `/spec-check` reads the result and lists drift.
4. Update `docs/REVIEW_NOTES.md`: remove the item the change closes, or add
   the one it opens.
5. Commit with the feature ID in the message.

## To recreate the repository

Run `prompts/00` through `prompts/12` in order, each in a fresh Claude Code
session or a cleared context, pasting the prompt verbatim and giving it
`SPEC.md` and `FEATURES.md` as context. Each prompt ends with the acceptance
checks for its slice; do not move to the next prompt until they pass.
`scripts/spec-check.sh` at the end is the gate for the whole.

## Rules

- Code never contradicts the spec. If it must, the spec changes first, in
  its own commit.
- A prompt produces one slice. A slice that needs two prompts is two
  features.
- Acceptance criteria are commands or greps, not adjectives.
- `docs/REVIEW_NOTES.md` is part of the spec: a known weakness is a planned
  feature change or a documented acceptance, never an unstated gap.
