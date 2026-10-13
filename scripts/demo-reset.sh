#!/usr/bin/env bash
# Put the environment back to a known state between rehearsals, so the live
# run looks the same as the practice run.
set -euo pipefail

kind delete cluster --name devsecops-demo 2>/dev/null || true
docker rm -f demo-postgres 2>/dev/null || true
find terraform -name 'terraform.tfstate*' -delete
find terraform -name '.terraform.lock.hcl' -delete
rm -rf terraform/envs/*/.terraform
echo "Reset. Run: make cluster && make db && make deploy ENV=dev"
