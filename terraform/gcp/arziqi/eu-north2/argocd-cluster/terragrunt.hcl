locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  mock_gke = {
    gke = {
      endpoint       = "203.0.113.1"
      ca_certificate = "Zm9v"
      name           = "mock"
    }
  }
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "gke" {
  config_path = "../gke"

  mock_outputs                            = local.mock_gke
  mock_outputs_allowed_terraform_commands = ["validate", "init"]
}

dependency "argocd_gke" {
  config_path = "../../../mensaah/eu-north1/gke"

  mock_outputs                            = local.mock_gke
  mock_outputs_allowed_terraform_commands = ["validate", "init"]
}

inputs = {
  project_id = local.account_vars.locals.project_id
  prod_cluster = {
    endpoint       = dependency.gke.outputs.gke.endpoint
    ca_certificate = dependency.gke.outputs.gke.ca_certificate
    name           = dependency.gke.outputs.gke.name
  }
  argocd_cluster = {
    endpoint       = dependency.argocd_gke.outputs.gke.endpoint
    ca_certificate = dependency.argocd_gke.outputs.gke.ca_certificate
  }
}
