variable "namespace" {
  type        = string
  default     = "argocd"
  description = "The namespace to deploy argocd into"
}

variable "argocd_url" {
  description = "Argo CD domain for Ingress"
  type        = string
  default     = null
}

variable "cluster" {
  description = "Cluster to deploy argocd into"
  type = map(string)
}

variable "repositories" {
  description = "A list of repository defintions"
  default     = {}
  # sensitive   = true
  type = map(object({
    url           = string
    type          = string
    username      = optional(string)
    password      = optional(string)
    sshPrivateKey = optional(string)
  }))
}

variable "repo_credential_templates" {
  description = "A list of repository credentials to be used as Templates for other repos"
  default     = {}
  # sensitive   = true
  type = map(object({
    url           = string
    type          = string
    username      = optional(string, null)
    password      = optional(string, null)
    sshPrivateKey = optional(string, null)
  }))
}

variable "chart_version" {
  description = "version of charts"
  type        = string
  default     = "8.3.0"
}

variable "image_tag" {
  description = "Image tag to install"
  default     = null
  type        = string
}

variable "config" {
  default     = {}
  description = "Additional config to be added to the Argocd configmap"
  type        = map(string)
}

variable "rbac_config" {
  default     = ""
  type        = string
  description = "Additional rbac config to be added to the Argocd rbac configmap"
}

variable "values" {
  type        = map(string)
  default     = {}
  description = "A terraform map of extra values to pass to the Argocd Helm"
}
