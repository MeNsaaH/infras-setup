terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>6.48"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

data "google_client_config" "default" {}

# The same Google identity is authorised on both projects, so one token
# serves both clusters.
provider "kubernetes" {
  alias                  = "argocd"
  host                   = "https://${var.argocd_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(var.argocd_cluster.ca_certificate)
}

provider "kubernetes" {
  alias                  = "prod"
  host                   = "https://${var.prod_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(var.prod_cluster.ca_certificate)
}
