locals {
  project_vars  = read_terragrunt_config(find_in_parent_folders("project.hcl"))
  regional_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  workspace     = reverse(split("/", get_terragrunt_dir()))[0]
}

engine {
  source  = "github.com/gruntwork-io/terragrunt-engine-opentofu"
  version = "v0.0.22"
}

generate "remote_state" {
  path      = "backend.terragrunt.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "gcs" {
    bucket = "${local.project_vars.locals.bucket_name}"
    prefix = "${local.project_vars.locals.project_id}/${local.workspace}"
  }
}
EOF
}
