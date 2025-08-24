locals {
  regional_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  project_vars  = read_terragrunt_config(find_in_parent_folders("project.hcl"))
}

include {
  path = find_in_parent_folders()
}


inputs = {
  project_id = local.project_vars.locals.project_id
  region     = local.regional_vars.locals.region
}
