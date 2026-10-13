# Kubernetes from scratch

Prepared for the conceptual half of the question. The runnable half is
`kind/cluster.yaml`.

## What a cluster is made of

**Control plane**
- `etcd`: the only stateful component. Everything else is a client of it.
  Quorum, so three or five members, never two or four. Backup is
  `etcdctl snapshot save`, and the restore has to be rehearsed.
- `kube-apiserver`: the only component that talks to etcd. Everything else
  talks to the apiserver. Authentication, then authorization (RBAC), then
  admission (mutating, then validating), then persistence.
- `kube-scheduler`: binds pods to nodes. Filter, then score.
- `kube-controller-manager`: the reconcile loops (node, replicaset, endpoints,
  service account, and so on).
- `cloud-controller-manager` when the cluster runs in a cloud: load balancers,
  node lifecycle, routes.

**Every node**
- `kubelet`: reads pod specs from the apiserver, drives the container runtime,
  reports status. The only node agent that matters for correctness.
- Container runtime through CRI: containerd or CRI-O.
- `kube-proxy` or a CNI that replaces it: service IPs to pod IPs.

**Networking**, which kubeadm does not install for you
- A CNI plugin: Calico, Cilium, flannel. Until one is installed, nodes are
  `NotReady` and CoreDNS stays `Pending`. This is the single most common
  "my cluster is broken" moment.
- CoreDNS, then an ingress controller if anything outside needs in.

## Bootstrap order, by hand

1. Hosts: swap off, kernel modules (`br_netfilter`, `overlay`), sysctls for
   bridged traffic and IP forwarding, a container runtime, consistent clocks.
2. Certificates: a cluster CA, then server and client certs for apiserver,
   kubelet, controller manager, scheduler, and etcd peers. `kubeadm` generates
   these; by hand it is `openssl` or `cfssl`, and the rotation plan is part of
   the design, not a follow-up.
3. etcd first, with TLS between peers and clients.
4. apiserver, pointed at etcd, with RBAC on and anonymous auth off.
5. controller-manager and scheduler, each with their own kubeconfig.
6. Join the workers: `kubeadm join` with a bootstrap token, or hand-built
   kubelet kubeconfigs. Approve the kubelet serving CSRs.
7. CNI. Now nodes go `Ready`.
8. CoreDNS, metrics-server, ingress, storage class.
9. Baseline posture before any workload: Pod Security Admission set to
   `restricted` on application namespaces, a default-deny NetworkPolicy per
   namespace, RBAC with no wildcard cluster-admin bindings, audit logging on
   the apiserver.

## What I would actually do, and why

For anything production-facing I would run a managed control plane and spend
the saved time on what the managed service does not give you: admission policy,
network policy, image provenance, upgrade rehearsal, and a tested etcd restore
if the control plane is self-managed. `kubeadm` for a self-managed cluster,
Cluster API if there will be many clusters. kind and k3s are for local work and
CI, not for production.

My own scope, stated plainly: I deploy, manage, and troubleshoot workloads
(kubectl, Helm installs and upgrades, Argo CD through an existing GitOps
setup), and I have debugged pod, networking, and resource failures on call. I
have not owned a cluster build in production. The reading above is how I would
approach one, and what I would want reviewed before I did.

## Troubleshooting order that has worked for me

`kubectl get events --sort-by=.lastTimestamp` before anything else, then
`describe` the pod, then logs with `--previous` if it restarted, then
`kubectl get endpoints` when a service looks up but nothing answers, then node
pressure and resource quotas. Most "the deployment is broken" turns out to be
an image pull, a readiness probe that is stricter than the application, a
missing secret, or a network policy that is doing exactly what it says.
