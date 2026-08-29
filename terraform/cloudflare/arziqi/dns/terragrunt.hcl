locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  zone_id   = local.account_vars.locals.arziqi_zone_id
  zone_name = local.account_vars.locals.zone_name
  tunnel_id = local.account_vars.locals.main_tunnel_id
}
