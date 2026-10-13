# P10: Decisions, threat model, monitoring (F20, F21)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Write the documentation that explains why, from the code and the spec.

`docs/adr/0001` records that ADRs exist and when one is required;
`0002` SOPS with age per environment, alternatives considered, consequences;
`0003` one chart with values layering over three manifest sets, with
Kustomize named as the defensible alternative; `0004` promotion by merge
with environment gates over environment branches or workspaces.

`docs/THREAT_MODEL.md`: a STRIDE table, one row per threat, what this repo
does about each, and a "known weaknesses, stated" list.
`docs/MONITORING.md`: the three questions a deploy has to answer, the
signals to put on this service, alerting principles, testing by layer, and
how a solution is evaluated. `docs/K8S_FROM_SCRATCH.md`: components,
bootstrap order by hand, what you would actually do, and a troubleshooting
order.

Acceptance:
- Every ADR has Date, Status, Context, Decision, Consequences
- Every weakness in THREAT_MODEL.md's list also appears in REVIEW_NOTES.md
  or is a documented demo convenience
