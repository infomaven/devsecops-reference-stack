# P04: Secrets design (F07)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Implement F07 without creating any real secret.

`.sops.yaml`: creation rules mapping `secrets/dev.enc.yaml`,
`secrets/staging.enc.yaml`, `secrets/prod.enc.yaml` to distinct age public
keys, placeholders clearly labeled, with `encrypted_regex` on prod so
structure stays readable in a diff. `secrets/README.md`: how to generate
keys, create the files, and the apply path that decrypts into
`TF_VAR_db_password` in the job environment and never to disk.
`docs/SECRETS.md`: the five rules, how it works here, what changes in a
real account (short-lived credentials from a secrets manager), and why
Terraform state is itself a secret. `.pre-commit-config.yaml` with gitleaks,
terraform fmt/validate/tflint, yamllint, ansible-lint. `.gitignore` for
state, plans, decrypted files, and age keys.

Acceptance:
- `grep -c "age1" .sops.yaml` is 3 and every key line contains the word
  placeholder or replace
- `git grep -n "password:" -- '*.yaml' '*.yml' '*.tf'` returns only the
  `existingSecret` reference and documented demo bootstrap values
