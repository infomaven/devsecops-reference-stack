output "namespace" {
  description = "Namespace the release landed in."
  value       = kubernetes_namespace.this.metadata[0].name
}

output "release_name" {
  description = "Helm release name, used by the smoke test."
  value       = helm_release.app.name
}
