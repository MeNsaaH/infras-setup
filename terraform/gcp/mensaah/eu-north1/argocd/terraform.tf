terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "~> 1.19"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}

provider "kubectl" {
    host  = "https://${var.cluster.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(var.cluster.ca_certificate)
    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "gke-gcloud-auth-plugin"
    }
}

provider "helm" {
    experiments = {
        manifest = true
    }
    kubernetes = {
        host  = "https://${var.cluster.endpoint}"
        token = data.google_client_config.provider.access_token
        cluster_ca_certificate = base64decode(var.cluster.ca_certificate)
        exec = {
            api_version = "client.authentication.k8s.io/v1beta1"
            command     = "gke-gcloud-auth-plugin"
        }
    }
}

provider "kubernetes" {
    host  = "https://${var.cluster.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(var.cluster.ca_certificate)
    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "gke-gcloud-auth-plugin"
    }
}