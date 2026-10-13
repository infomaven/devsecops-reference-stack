# 0022. Workflow input interpolated directly into shell

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-78 (OS command injection)
- **Severity:** Low. Not exploitable today: the only caller passes three hardcoded values. It becomes exploitable the moment a caller passes anything user-controlled.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`.github/workflows/apply.yml` expands `${{ inputs.environment }}` inside
`run:` blocks at lines 37, 41, 42, 46, 52, and 57. GitHub substitutes the
expression into the script text before the shell parses it, so a value
containing shell syntax would execute. The input is declared as a free
string (lines 6-9) with no allowed-values check.

Today `promote.yml` is the only caller and passes `dev`, `staging`, and
`prod` as literals. Adding a `workflow_dispatch` input, or calling
`apply.yml` from another workflow with a derived value, would turn this
into command execution in the job that holds the SOPS key.

## How it got here

Copied pattern. Inline `${{ }}` in `run:` is the form most workflow
examples use.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
