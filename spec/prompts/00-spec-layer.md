# P00: Spec layer

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

You are setting up the spec-driven scaffolding for `devsecops-reference-stack`.
Read `spec/SPEC.md` and `spec/FEATURES.md`. Create nothing outside `spec/`,
`scripts/spec-check.sh`, `.claude/commands/`, and the Makefile.

Produce:
1. `spec/CHANGE-PROTOCOL.md` as specified.
2. `scripts/spec-check.sh`: bash 3.2 compatible (macOS), no associative
   arrays. For each feature in FEATURES.md with a mechanical criterion, test
   that the named files exist and that the key strings are present. Print one
   line per feature: PASS, PARTIAL, or FAIL, with the reason. Exit non-zero
   on any FAIL. Run yamllint if installed.
3. `.claude/commands/spec-slice.md` and `.claude/commands/spec-check.md`.
4. A `spec-check` target in the Makefile.

Acceptance:
- `bash -n scripts/spec-check.sh` is clean
- `make spec-check` runs and reports every feature ID in FEATURES.md
- `yamllint -s .` passes
