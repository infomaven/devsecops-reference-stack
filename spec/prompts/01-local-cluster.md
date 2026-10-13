# P01: Local cluster (F01)

> Paste into Claude Code from the repository root. Load `spec/SPEC.md` and
> `spec/FEATURES.md` first. Do not move to the next prompt until the
> acceptance checks at the end pass.

Implement F01. Create `kind/cluster.yaml`: one control-plane node, two
workers, pod and service subnets stated explicitly, host port 8080 mapped to
node port 30080, the control plane labeled `ingress-ready=true`. Leave
`disableDefaultCNI: false` with a comment explaining what flipping it shows
in a Kubernetes-from-scratch walkthrough.

Also create `scripts/bootstrap.sh`: a preflight that checks for docker, kind,
kubectl, helm, terraform, ansible-playbook, sops, age-keygen, conftest, and
the psycopg2 Python module, prints found or MISSING for each, and exits
non-zero if anything is missing.

Acceptance:
- `kind create cluster --config kind/cluster.yaml --name devsecops-demo`
  succeeds and `kubectl get nodes` shows three Ready nodes
- `bash -n scripts/bootstrap.sh` is clean
