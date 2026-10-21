#!/usr/bin/env bash
# Choose what the pipeline deploys: the stand-in service, or a real
# application. Writes an application profile to apps/<name>.yaml (a Helm values
# overlay) and records the choice in apps/.selected, which `make plan`,
# `make deploy`, and `make policy` read. See apps/README.md.
#
#   scripts/select-app.sh                      ask for each setting
#   scripts/select-app.sh --standin            go back to the stand-in
#   scripts/select-app.sh --name orders --image ghcr.io/acme/orders:1.4.2 \
#     --port 3000 --health /healthz --writable /tmp
#   scripts/select-app.sh --name orders --source ../orders   # docker build
#
# bash 3.2 compatible (macOS ships it).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APPS="$ROOT/apps"
CLUSTER="devsecops-demo"

name="" image="" source="" port="" health="" writable="" uid=""
interactive=1
[ $# -gt 0 ] && interactive=0

die() { echo "select-app: $*" >&2; exit 1; }

usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --standin)  rm -f "$APPS/.selected"
                echo "Selected: the stand-in service (helm/paymentsvc/values.yaml)."
                exit 0 ;;
    --name)     name="${2:-}"; shift 2 ;;
    --image)    image="${2:-}"; shift 2 ;;
    --source)   source="${2:-}"; shift 2 ;;
    --port)     port="${2:-}"; shift 2 ;;
    --health)   health="${2:-}"; shift 2 ;;
    --writable) writable="${2:-}"; shift 2 ;;
    --uid)      uid="${2:-}"; shift 2 ;;
    -h|--help)  usage 0 ;;
    *)          echo "select-app: unknown argument: $1" >&2; usage 1 ;;
  esac
done

ask() {  # variable prompt default
  local reply
  if [ "$interactive" -eq 1 ]; then
    read -r -p "$2 [$3]: " reply
    eval "$1=\${reply:-\$3}"
  else
    eval "[ -n \"\${$1}\" ] || $1=\$3"
  fi
}

if [ "$interactive" -eq 1 ]; then
  echo "Select the application this pipeline deploys."
  echo "  1) the stand-in service (nginx-unprivileged)"
  echo "  2) a published container image"
  echo "  3) a local source directory with a Dockerfile"
  read -r -p "Choice [1]: " choice
  case "${choice:-1}" in
    1) exec "$0" --standin ;;
    2) read -r -p "Image (repository:tag): " image ;;
    3) read -r -p "Source directory: " source ;;
    *) die "choose 1, 2, or 3" ;;
  esac
  read -r -p "Profile name (lowercase, e.g. orders): " name
fi

[ -n "$image" ] && [ -n "$source" ] && die "give --image or --source, not both"
[ -z "$image" ] && [ -z "$source" ] && die "give --image or --source"
echo "$name" | grep -Eq '^[a-z][a-z0-9-]{0,30}$' \
  || die "profile name must be lowercase letters, digits, and dashes"
[ "$name" = "standin" ] && die "'standin' is reserved; use --standin"

# Build a local source tree into an image whose tag names the commit, so the
# tag means something and is never "latest" (I1).
if [ -n "$source" ]; then
  [ -f "$source/Dockerfile" ] || die "no Dockerfile in $source"
  if tag=$(git -C "$source" rev-parse --short HEAD 2>/dev/null); then
    [ -z "$(git -C "$source" status --porcelain 2>/dev/null)" ] || tag="$tag-dirty"
  else
    tag="build-$(date +%Y%m%d%H%M%S)"
  fi
  image="local/$name:$tag"
  echo "+ docker build -t $image $source"
  docker build -t "$image" "$source"
fi

# Split repository:tag. A colon after the last slash is the tag; a colon
# before it is a registry port.
repo="${image%:*}"; tag="${image##*:}"
case "$tag" in */*) repo="$image"; tag="" ;; esac
[ "$repo" = "$image" ] && tag=""
case "$image" in *@sha256:*) die "digests are not supported yet; use repository:tag" ;; esac
[ -n "$tag" ] && [ "$tag" != "latest" ] \
  || die "image needs an explicit tag, not latest or empty (I1): $image"

ask port     "Container port (the app must listen on it as non-root)" 8080
ask health   "HTTP path for liveness, readiness, and helm test" /
ask writable "Writable directories, comma-separated (root fs is read-only)" /tmp
ask uid      "Non-root user ID to run as" 10001

echo "$port" | grep -Eq '^[0-9]+$' && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ] \
  || die "port must be 1024-65535; with all capabilities dropped, a non-root process cannot bind below 1024"
case "$health" in /*) ;; *) die "health path must start with /" ;; esac
echo "$uid" | grep -Eq '^[0-9]+$' && [ "$uid" -gt 0 ] || die "user ID must be a positive integer (I2)"

mkdir -p "$APPS"
profile="$APPS/$name.yaml"
{
  echo "---"
  echo "# Application profile: $name. Written by scripts/select-app.sh on"
  echo "# $(date +%Y-%m-%d). Layered after values-<env>.yaml. Sets only what differs"
  echo "# about the application; the security context stays the chart's (I13)."
  echo "image:"
  echo "  repository: $repo"
  echo "  tag: \"$tag\""
  echo "service:"
  echo "  port: $port"
  echo "podSecurityContext:"
  echo "  runAsUser: $uid"
  echo "  fsGroup: $uid"
  echo "probes:"
  echo "  liveness:"
  echo "    path: $health"
  echo "  readiness:"
  echo "    path: $health"
  echo "writablePaths:"
  echo "$writable" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep . | sed 's/^/  - /' || true
} > "$profile"
echo "Wrote apps/$name.yaml."

# Same gate CI applies: render every environment with the profile and test it.
if command -v helm >/dev/null 2>&1 && command -v conftest >/dev/null 2>&1; then
  for env in dev staging prod; do
    echo "+ policy check: $env"
    helm template paymentsvc "$ROOT/helm/paymentsvc" \
      -f "$ROOT/helm/paymentsvc/values-$env.yaml" -f "$profile" \
      | conftest test --policy "$ROOT/policy/kubernetes" - \
      || die "apps/$name.yaml fails policy for $env; fix the profile or the image"
  done
else
  echo "helm or conftest not installed; run make policy before deploying."
fi

echo "$name" > "$APPS/.selected"
echo "Selected: $name ($repo:$tag)."

# A locally built image is not in any registry; kind has to be given it.
if [ -n "$source" ]; then
  if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
    echo "+ kind load docker-image $image --name $CLUSTER"
    kind load docker-image "$image" --name "$CLUSTER"
  else
    echo "No kind cluster yet. After make cluster, run:"
    echo "  kind load docker-image $image --name $CLUSTER"
  fi
fi

echo
echo "Next: make deploy ENV=dev && make smoke ENV=dev"
echo "Back to the stand-in: make select-app ARGS=--standin"
