# Change protocol

The spec was extracted from the code on Oct 11, 2026, after the first build.
That is the honest order of events, and it is also how any inherited
codebase gets a spec: read the code, write down what it does and why, then
make the code answer to the document from that point on.

## Before editing any file

This applies to every tracked file: source code, configuration, workflows,
scripts, and documentation, including Markdown and diagrams. The prompts in
`prompts/` produce all of them, so every one of them answers to the spec.

1. Find the owner. Look the file up in the Files column of `FEATURES.md`,
   in the Features table and the Planned changes table. The row's Prompt
   column names the prompt that produces it: a numbered prompt, or MOD.
2. If a row owns the file and the change stays inside that row's acceptance
   criteria, make the change under that feature, using `/spec-slice <ID>` or
   the prompt the row names.
3. If a row owns the file but the change goes beyond its acceptance
   criteria, amend the row first. If a numbered prompt describes the file's
   contents, amend that prompt in the same commit, so that rebuilding from
   the prompts produces the new version.
4. If no row owns the file, add one first: extend the Files column of the
   feature it belongs to, or add a new feature. Do not edit an unowned file.

The spec itself (`spec/`) is owned by F24 and is edited directly; that edit
is the first step above. Files ignored by `.gitignore` are not tracked and
need no owner.

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
  its own commit. "Code" means every output artifact, documentation
  included.
- Every tracked file outside `spec/` is listed in the Files column of at
  least one feature row. A file with no owner is drift, the same as a
  failed acceptance check.
- A numbered prompt stays accurate to the files it produces. When a change
  alters what a prompt describes, the prompt changes with the spec, before
  the file.
- A prompt produces one slice. A slice that needs two prompts is two
  features.
- Acceptance criteria are commands or greps, not adjectives.
- `docs/REVIEW_NOTES.md` is part of the spec: a known weakness is a planned
  feature change or a documented acceptance, never an unstated gap.
