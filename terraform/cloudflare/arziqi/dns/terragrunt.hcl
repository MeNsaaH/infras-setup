locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "tunnel" {
  config_path = "../../shared/tunnel"

  mock_outputs                            = { prod_tunnel_id = "00000000-0000-0000-0000-000000000000" }
  mock_outputs_allowed_terraform_commands = ["validate", "init"]
  # The tunnel stack's state predates the prod tunnel, so the output is missing
  # until that stack is applied.
  mock_outputs_merge_with_state = true
}

inputs = {
  zone_id        = local.account_vars.locals.arziqi_zone_id
  zone_name      = local.account_vars.locals.zone_name
  tunnel_id      = local.account_vars.locals.main_tunnel_id
  prod_tunnel_id = dependency.tunnel.outputs.prod_tunnel_id
}
