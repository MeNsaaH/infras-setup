variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

resource "google_artifact_registry_repository" "azana_registry" {
  project  = var.project_id
  location = var.region
  repository_id = "azana-registry"
  description = "Azana Registry"
  format = "DOCKER"
}