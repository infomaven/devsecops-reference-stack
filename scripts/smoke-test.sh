#!/usr/bin/env bash
# Post-deploy checks. This is the difference between "terraform applied" and
# "the service works", and it is what gates promotion to the next environment.
set -euo pipefail

ENV="${1:-dev}"
NS="paymentsvc-${ENV}"
RELEASE="paymentsvc"

echo "==> rollout status"
kubectl -n "$NS" rollout status "deploy/${RELEASE}-paymentsvc" --timeout=120s

echo "==> every pod ready"
not_ready=$(kubectl -n "$NS" get pods -l "app.kubernetes.io/instance=${RELEASE}" \
  -o jsonpath='{range .items[*]}{.status.containerStatuses[*].ready}{"\n"}{end}' | grep -c false || true)
if [ "$not_ready" -ne 0 ]; then
  echo "FAIL: $not_ready container(s) not ready" >&2
  kubectl -n "$NS" get pods
  exit 1
fi

echo "==> helm test (in-cluster HTTP check)"
helm test "$RELEASE" -n "$NS" --timeout 2m

echo "==> no plaintext password landed in the ConfigMap"
if kubectl -n "$NS" get configmap "${RELEASE}-paymentsvc" -o yaml | grep -iq "password"; then
  echo "FAIL: a password-like key is in the ConfigMap" >&2
  exit 1
fi

echo "==> security context held"
kubectl -n "$NS" get deploy "${RELEASE}-paymentsvc" \
  -o jsonpath='{.spec.template.spec.securityContext.runAsNonRoot}' | grep -q true

echo "==> network policy present"
kubectl -n "$NS" get networkpolicy default-deny >/dev/null

echo "PASS: ${ENV}"
