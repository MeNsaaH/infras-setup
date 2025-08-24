locals {
  regional_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  project_vars  = read_terragrunt_config(find_in_parent_folders("project.hcl"))
  secrets = yamldecode(sops_decrypt_file("${find_in_parent_folders("secrets.yaml")}"))
}

include {
  path = find_in_parent_folders()
}

dependency "gke" {
  config_path = "../gke"
}

inputs =  {
  cluster_name = "main-gke-01"
  cluster = {
    endpoint = dependency.gke.outputs.gke.endpoint
    ca_certificate = dependency.gke.outputs.gke.ca_certificate
    cluster_id = dependency.gke.outputs.gke.cluster_id
    name = dependency.gke.outputs.gke.name
  }
  repo_credential_templates = {
    mensaah-github = {
      url      = "https://github.com/mensaah/"
      type     = "git"
      username = "mensaah"
      password = local.secrets.mensaah-github.PAT
    }
  }
}
