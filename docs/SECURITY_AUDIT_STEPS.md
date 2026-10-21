# Security audit: steps

How to audit this repository with `security-engineer-toolkit`. Why a second
repository does the audit, and what each one covers, is in
`SECURITY_AUDIT_OVERVIEW.md`.

## Before you start

- Install the toolkit's slash commands in Claude Code.
- Optionally install the local scanners `make exercise` uses: Gitleaks,
  Semgrep, Trivy, and Checkov. Any that are missing are skipped.
- Audit only code you own or are authorized to review. The toolkit is static
  and reasoning-based: its output is a code review, not a penetration test
  or dynamic testing.

## Steps

**1. Run the local scanners.** From the repository root:

```bash
make exercise      # runs the installed scanners, then prints the commands for steps 2 to 5
```

**2. Intake.** In Claude Code, from the repository root:

```
/setup-target .
```

Answer its questions: the stack is Terraform, Helm, Ansible, and shell; the
risk profile is a local demo with no real data; authorization is your own
code; the effort budget is a few hours.

**3. Review the generated code (Scenario B).** This repository was produced
in one Claude Code session, so it is reviewed as one large diff from nothing:

```
/security-review
```

Then read the toolkit's `AI-AGENT-THREAT-MODEL.md` and check for what
generation tends to leave behind: plausible-looking example credentials,
hardcoded connection strings, overly permissive defaults. The three
placeholder age keys in `.sops.yaml` and `POSTGRES_PASSWORD=bootstrap` in the
Makefile are deliberate and documented. Anything else is a real finding.

**4. Sweep the executable code.** The shell scripts and the Ansible Jinja
templating are the code that runs:

```
/security-sweep scripts
/security-sweep ansible
```

**5. Record each finding.** Write one file per finding in `findings/`, using
`findings/0000-template.md`. `/remediation-note` drafts the "why it
happens" and "the guardrail, not just the fix" sections.

**6. Close each finding** in one of three ways:

- fix the code;
- add a Rego rule in `policy/` that fails the build if the problem comes
  back; or
- record it as an accepted risk in `docs/THREAT_MODEL.md` under known
  weaknesses.

A policy rule is the strongest outcome, because it cannot regress silently.
