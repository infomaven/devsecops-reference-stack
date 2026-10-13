# Secrets

## Rules this repo follows

1. No plaintext secret in git, ever, including in a values file, a tfvars file,
   or a workflow.
2. A secret has exactly one home per environment, and the environments do not
   share keys.
3. CI gets secrets by identity (OIDC, environment-scoped keys), not by storing
   long-lived credentials.
4. Anything decrypted stays in process memory or an environment variable for
   the life of one job. Nothing is written to the workspace.
5. There is a scanner on the way in (pre-commit gitleaks) and a scanner in CI,
   because rule 1 is a human promise and humans break it.

## How it works here

- `.sops.yaml` maps each `secrets/<env>.enc.yaml` to its own age key.
  `encrypted_regex` on prod keeps structure readable while values stay sealed.
- Terraform takes the value as a `sensitive` variable and writes it into a
  Kubernetes Secret. The chart only ever references it by name
  (`database.existingSecret`), so a rendered manifest never contains it.
- The Rego policy fails any Deployment that sets a password-shaped environment
  variable inline rather than through `valueFrom`.
- Ansible keeps database passwords in `group_vars/vault.yml` under
  ansible-vault, with `no_log: true` on the tasks that use them.

## What I would change in a real account

SOPS with age is right for a small repo. At scale the database password should
not be a long-lived string at all: AWS Secrets Manager or Vault issuing a
short-lived credential, rotated automatically, with the application reading it
at startup through IRSA or the Vault agent. The pipeline then holds no database
secret, only the right to assume a role. That removes the rotation problem
instead of scheduling it.

State files count as secrets. Terraform state holds the secret value in
plaintext, so the backend needs encryption at rest, versioning, strict access,
and no public read, which is the first thing I check on any account I inherit.
