# secrets/

Encrypted files only. `dev.enc.yaml`, `staging.enc.yaml`, and `prod.enc.yaml`
are SOPS files encrypted to an age key per environment, so a dev key cannot
decrypt prod.

Generate your keys and create the files:

```bash
age-keygen -o ~/.config/sops/age/keys.txt        # prints the public key
# put the public key in .sops.yaml, then:
sops secrets/dev.enc.yaml
```

The pipeline decrypts at apply time and passes the value straight into
Terraform without writing plaintext to disk:

```bash
TF_VAR_db_password="$(sops -d --extract '["db_password"]' secrets/dev.enc.yaml)" \
  terraform -chdir=terraform/envs/dev apply -auto-approve
```

In CI the age private key is a repository secret scoped to the environment, so
the prod key only exists in jobs that a reviewer approved. gitleaks runs on
every pull request as the backstop.
