locals {
  regional_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_vars  = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc = {
      network_name             = "main"
      subnets_names            = ["subnet-01"]
      subnets_secondary_ranges = [[{ range_name = "pods" }, { range_name = "services" }]]
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "init"]
}

inputs = {
  project_id = local.account_vars.locals.project_id
  region     = local.regional_vars.locals.region
  vpc        = dependency.vpc.outputs.vpc
}
