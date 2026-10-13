variable "environment" {
  description = "dev, staging, or prod. Selects the Helm values file."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of dev, staging, prod."
  }
}

variable "namespace" {
  description = "Kubernetes namespace for this environment."
  type        = string
}

variable "image_tag" {
  description = "Explicit image tag. Floating tags are rejected."
  type        = string

  validation {
    condition     = var.image_tag != "latest" && length(var.image_tag) > 0
    error_message = "image_tag must be an explicit version, not latest."
  }
}

variable "db_password" {
  description = "Injected at apply time from SOPS or a secrets manager. Never committed."
  type        = string
  sensitive   = true
}

variable "labels" {
  description = "Labels applied to every resource this module owns."
  type        = map(string)
  default     = {}
}
