resource "kubernetes_service_account_v1" "argocd_manager" {
  provider = kubernetes.prod

  metadata {
    name      = "argocd-manager"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "argocd_manager" {
  provider = kubernetes.prod

  metadata {
    name = "argocd-manager"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.argocd_manager.metadata[0].name
    namespace = "kube-system"
  }
}

# Since Kubernetes 1.24 a ServiceAccount no longer gets a token Secret on its
# own; this one is created explicitly so ArgoCD has a long-lived credential.
resource "kubernetes_secret_v1" "argocd_manager_token" {
  provider = kubernetes.prod

  metadata {
    name      = "argocd-manager-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.argocd_manager.metadata[0].name
    }
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

# ArgoCD discovers destination clusters from Secrets carrying this label. The
# `name` here is what Applications reference as destination.name.
locals {
  argocd_name = "arziqi-${var.prod_cluster.name}"
}

resource "kubernetes_secret_v1" "cluster" {
  provider = kubernetes.argocd

  metadata {
    name      = "cluster-${local.argocd_name}"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }

  data = {
    name   = local.argocd_name
    server = "https://${var.prod_cluster.endpoint}"
    config = jsonencode({
      bearerToken = kubernetes_secret_v1.argocd_manager_token.data["token"]
      tlsClientConfig = {
        caData = var.prod_cluster.ca_certificate
      }
    })
  }
}
