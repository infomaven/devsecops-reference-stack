# Exercising this stack with the security-engineer-toolkit

This repository is a Claude Code generated application. That is not an
aside; it is exactly the case `security-engineer-toolkit` calls **Scenario
B**, and it is the honest way to demonstrate both repos at once: one built
the thing, the other audits it, and the audit is the part most people skip.

## Why the two fit together

The one-page version, for opening on a screenshare, is `TWO_REPOS.md`.

The toolkit's own `FRAMEWORK-ALIGNMENT.md` states its boundaries plainly.
Those boundaries are where this repository lives.

| Toolkit says | This repository |
|---|---|
| SSDF PW.8, dynamic testing: **none** | `helm test`, `scripts/smoke-test.sh`, promotion gated on a live check |
| SSDF PS, release integrity: **none** | Promotion by merge, environment reviewers, deployment record, rollback |
| SAMM Operations: **none**, entirely pre-production | Kubernetes posture, network policy, monitoring, drift detection |
| SAMM Design, security architecture: **none** | `docs/THREAT_MODEL.md`, the ADRs, policy as code in `policy/` |
| Verification / PW.7 code review: **core** | Not attempted here. The toolkit does it |

One sentence for the interview: *the toolkit verifies code, this stack
covers the design and operations half the toolkit says it does not, and I
run them against each other.*

## The loop

**1. Intake.** In Claude Code, from this repository:

```
/setup-target .
```

Answer its questions honestly: stack is Terraform, Helm, Ansible, and
shell; risk profile is a local demo with no real data; authorization is
your own code; effort budget is a few hours.

**2. Scenario B review, on the generation itself.** This repo was produced
in one session, so it is one large diff from nothing:

```
/security-review
```

Then read `AI-AGENT-THREAT-MODEL.md` and check specifically for what
generation tends to leave behind: plausible-looking example credentials,
hardcoded connection strings, overly permissive defaults. The three
placeholder age keys in `.sops.yaml` and the `POSTGRES_PASSWORD=bootstrap`
in the Makefile are deliberate and documented; anything else it finds is a
real finding.

**3. Sweep what is actually code.** The shell scripts and the Ansible
Jinja templating are the executable surface:

```
/security-sweep scripts
/security-sweep ansible
```

**4. Record findings.** One file per finding in `findings/`, using the
template there. `/remediation-note` writes the "why it happens" and "the
guardrail, not just the fix" sections for you.

**5. Close the loop.** Every finding either becomes a fix, a Rego rule in
`policy/`, or a row in `docs/THREAT_MODEL.md` under known weaknesses. A
finding that becomes a policy rule is the strongest outcome, because it
cannot regress silently.

```bash
make exercise      # prints this loop and runs whatever local scanners you have
```

## CI

`.github/workflows/security-scan.yml` is the toolkit's template, copied
unmodified: Gitleaks, Semgrep, Trivy, and a CycloneDX SBOM, with every
action pinned by commit SHA and every scanner binary checksum-verified.
Update it by re-copying from the toolkit rather than editing it here.

`pr-checks.yml` keeps only what that template does not cover: the
infrastructure scanners, the Rego policy gate, and the Terraform plans.

## Optional: run a vulnerable application through the hardened chart

The toolkit ships WebGoat as a practice target. Deploying it through this
chart is a useful demonstration precisely because **it fails**:

```bash
helm template webgoat helm/paymentsvc \
  --set image.repository=webgoat/webgoat \
  --set image.tag=2026.1 \
  | conftest test --policy policy/kubernetes -
```

WebGoat needs a writable root filesystem and will not run under the
chart's defaults. The policy says no, and the only way forward is an
explicit waiver in a values file that a reviewer has to approve. That is
the whole argument for policy as code in one screen: the guardrail held
against a workload that genuinely wanted to break it, and the exception is
a visible, reviewable artifact rather than a quiet edit.

Do not deploy WebGoat to anything but the local kind cluster.

## What to say, and what not to

Say that the stack was generated and then audited with your own toolkit,
and that you enabled the review path before trusting the output. Say that
the toolkit is static and reasoning-based, so it is not dynamic testing
and not a DAST substitute.

Do not describe toolkit output as a penetration test, and do not point any
of this at infrastructure you do not own.
