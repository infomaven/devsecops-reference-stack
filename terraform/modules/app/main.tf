# One module, three environments. The only thing that changes between them is
# the variable values, so a reviewer reads a plan diff rather than a diff of
# three near-identical configurations.

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
    labels = merge(var.labels, {
      "environment"                  = var.environment
      "kubernetes.io/metadata.name"  = var.namespace
      "pod-security.kubernetes.io/enforce" = "restricted"
    })
  }
}

# Default-deny inside the namespace. The chart then opens exactly the paths the
# service needs. Terraform owns the namespace-wide posture; Helm owns the
# workload.
resource "kubernetes_network_policy" "default_deny" {
  metadata {
    name      = "default-deny"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

# The database password is read from a SOPS-decrypted file at apply time and
# never written to the repository. In a real account this is an AWS Secrets
# Manager data source instead; see docs/SECRETS.md.
resource "kubernetes_secret" "db" {
  metadata {
    name      = "paymentsvc-db"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = var.labels
  }

  data = {
    password = var.db_password
  }

  type = "Opaque"
}

resource "helm_release" "app" {
  name      = "paymentsvc"
  chart     = "${path.module}/../../../helm/paymentsvc"
  namespace = kubernetes_namespace.this.metadata[0].name

  values = [
    file("${path.module}/../../../helm/paymentsvc/values-${var.environment}.yaml"),
  ]

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  # Fail the apply rather than leave a half-rolled deployment behind.
  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 300

  depends_on = [kubernetes_secret.db]
}
