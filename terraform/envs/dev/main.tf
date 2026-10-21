terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
  }

  # Local state for the demo. In a real account: an S3 backend with versioning,
  # SSE-KMS, and DynamoDB state locking, one key per environment. See
  # docs/adr/0004-terraform-promotion-model.md.
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-devsecops-demo"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "kind-devsecops-demo"
  }
}

variable "db_password" {
  description = "Supplied by the pipeline: sops -d secrets/dev.enc.yaml | yq .db_password"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "Set by CI to the tag built from the merge commit. Null keeps the tag in the chart values or app profile."
  type        = string
  default     = null
}

variable "app_values_file" {
  description = "Application profile from apps/, set by make from apps/.selected. Empty deploys the stand-in."
  type        = string
  default     = ""
}

module "app" {
  source = "../../modules/app"

  environment     = "dev"
  namespace       = "paymentsvc-dev"
  image_tag       = var.image_tag
  app_values_file = var.app_values_file
  db_password     = var.db_password

  labels = {
    "app.kubernetes.io/part-of" = "payments"
    "owner"                     = "platform"
    "cost-center"               = "eng-platform"
    "managed-by"                = "terraform"
  }
}

output "namespace" {
  value = module.app.namespace
}
