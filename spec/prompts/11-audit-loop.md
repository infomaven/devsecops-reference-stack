# P11: Audit loop with the toolkit (F22)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Implement F22. This repository is a Claude Code generated application, which
is `security-engineer-toolkit`'s Scenario B.

`docs/SECURITY_AUDIT_STEPS.md`: the complementarity table (what the toolkit covers
versus what this stack covers, citing the toolkit's FRAMEWORK-ALIGNMENT
gaps), the loop (`/setup-target .`, `/security-review`, `/security-sweep`
over scripts and ansible, record findings, close each as fix, policy rule,
or accepted), CI notes, the optional WebGoat-through-the-chart rejection,
and what to say and not say. `docs/SECURITY_AUDIT_OVERVIEW.md`: the one-page self-audit argument.
`findings/README.md` and `findings/0000-template.md`. `make exercise`
runs local scanners and prints the Claude Code commands.

Acceptance:
- `make exercise` runs without error when no scanners are installed (each
  is tolerated) and prints the five commands
- `docs/SECURITY_AUDIT_OVERVIEW.md` is under one printed page
