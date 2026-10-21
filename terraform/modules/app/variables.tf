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
  description = "Explicit image tag, or null to keep the tag in the chart values or app profile. Floating tags are rejected."
  type        = string
  default     = null

  validation {
    condition     = var.image_tag == null ? true : (var.image_tag != "latest" && length(var.image_tag) > 0)
    error_message = "image_tag must be an explicit version, not latest."
  }
}

variable "app_values_file" {
  description = "Absolute path to an application profile from apps/, layered after the environment values. Empty deploys the stand-in."
  type        = string
  default     = ""

  validation {
    condition     = var.app_values_file == "" || endswith(var.app_values_file, ".yaml")
    error_message = "app_values_file must be empty or a .yaml application profile."
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
