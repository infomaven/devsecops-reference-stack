# P03: Terraform module and environments (F05, F06)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Implement F05 and F06.

`terraform/modules/app/`: `main.tf` with a `kubernetes_namespace` carrying
`environment`, ownership labels from a `labels` variable, and
`pod-security.kubernetes.io/enforce: restricted`; a default-deny
`kubernetes_network_policy` for Ingress and Egress; a `kubernetes_secret`
named `paymentsvc-db` from a `sensitive` `db_password` variable; a
`helm_release` of the local chart with the environment's values file,
`image.tag` set from a variable, `atomic`, `cleanup_on_fail`, `wait`, and
`depends_on` the secret. `variables.tf` validates `environment` against
dev/staging/prod and rejects `image_tag` of `latest` or empty. `outputs.tf`
exposes namespace and release name.

`terraform/envs/{dev,staging,prod}/main.tf`: required providers
(kubernetes, helm), a local backend with a comment naming the real one (S3
with versioning, SSE-KMS, DynamoDB locking, one key per environment, OIDC
role per environment), providers pointed at `kind-devsecops-demo`, the two
variables, one module call with labels, one output. Nothing else (I4).

`terraform/README.md` explains the layout and promotion by merge.

Acceptance:
- `terraform fmt -check -recursive terraform` is clean
- `terraform -chdir=terraform/envs/dev init && terraform -chdir=terraform/envs/dev validate` passes
- `grep -c "^resource" terraform/envs/*/main.tf` is 0 for every root
