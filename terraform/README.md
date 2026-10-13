# Terraform layout

```
modules/app        the only place resources are declared
envs/dev           thin root module: provider, variables, one module call
envs/staging       same, different values
envs/prod          same, different values and a stricter review gate
```

Promotion is a merge, not a copy. CI runs `plan` for all three environments on
every pull request, applies `dev` automatically on merge, and waits for a named
reviewer before `staging` and again before `prod`
(`.github/workflows/promote.yml`). The same commit produces all three applies,
so "what is in prod" is answerable by `git log`.

Local state is a demo convenience. For a real account use an S3 backend with
versioning, SSE-KMS, and DynamoDB locking, one state key per environment, and a
separate role per environment assumed through GitHub OIDC so no long-lived AWS
keys exist in CI.
