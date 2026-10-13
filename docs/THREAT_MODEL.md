# Threat model (STRIDE, one page)

Scope: the pipeline and the deployed service, not the application logic.

| Threat | Where it bites | What this repo does |
|---|---|---|
| Spoofing | A workflow from a fork runs with repository credentials | `pull_request` jobs get read-only tokens; applies run only from `main`, behind GitHub environments with required reviewers |
| Tampering | Someone edits prod directly, or lands an unreviewed change | CODEOWNERS on `terraform/envs/prod` and `policy/`; nightly drift plan opens an issue on any out-of-band change |
| Repudiation | "Nobody knows who changed prod" | Every apply is a merge commit; `apply.yml` records env, sha, and result; ADRs hold the reasoning |
| Information disclosure | Secrets in git, state, logs, or a rendered manifest | SOPS per environment, `sensitive` Terraform variables, `no_log` in Ansible, Rego rule against inline password env vars, gitleaks in two places |
| Denial of service | A bad rollout takes the service down | Helm `atomic` plus `wait`, PDB in staging and prod, smoke test gate, automatic rollback |
| Elevation of privilege | Container escape, or an over-granted database role | `runAsNonRoot`, dropped capabilities, read-only root filesystem, seccomp RuntimeDefault, restricted Pod Security Admission, default-deny NetworkPolicy, no superuser database role for the application |

## Known weaknesses, stated rather than hidden

- The database password is long-lived. Short-lived credentials from a secrets
  manager would remove the rotation problem; see `docs/SECRETS.md`.
- Local Terraform state for the demo. Real state needs an encrypted, versioned,
  locked backend.
- No image signing or provenance attestation. Cosign and a verification
  admission policy would be the next addition.
- `helm test` checks that the service answers, not that it is correct.
