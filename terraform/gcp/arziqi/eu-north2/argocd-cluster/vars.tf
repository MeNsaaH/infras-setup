variable "project_id" {
  type = string
}

variable "argocd_cluster" {
  type        = map(string)
  description = "Cluster running ArgoCD (endpoint, ca_certificate)."
}

variable "prod_cluster" {
  type        = map(string)
  description = "Cluster to register (endpoint, ca_certificate, name)."
}
