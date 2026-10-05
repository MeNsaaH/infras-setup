locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  account_id  = local.account_vars.locals.account_id
  tunnel_id   = local.account_vars.locals.main_tunnel_id
  tunnel_name = "main-gke-tunnel"

  # Adopted as-is from the live tunnel. The catch-all must stay last.
  ingress_rules = [
    {
      hostname = "argocd.labtime.work"
      service  = "http://argocd-server.argocd:80"
      # Present but empty on the live tunnel; kept so adoption is a no-op.
      origin_request = {}
    },
    {
      # Pre-rebrand hostname still serving the production backend. Removing it
      # is a product decision (does the old brand keep answering?), not a
      # cleanup to slip into an import.
      hostname = "api.flego.io"
      service  = "http://azana-web.azana:8080"
    },
    {
      hostname = "grafana.labtime.work"
      service  = "http://grafana.monitoring:80"
    },
    {
      # Kept until the DNS record moves to the prod tunnel and prod answers;
      # remove it in a follow-up apply after that.
      hostname = "api.arziqi.com"
      service  = "http://azana-web.azana:8080"
    },
    {
      hostname = "api-staging.arziqi.com"
      service  = "http://azana-web.azana:8080"
    },
    {
      service = "http_status:404"
    },
  ]

  prod_tunnel_name = "prod-gke-tunnel"

  prod_ingress_rules = [
    {
      hostname = "api.arziqi.com"
      service  = "http://azana-web.azana:8080"
    },
    {
      hostname = "grafana-prod.labtime.work"
      service  = "http://grafana.monitoring:80"
    },
    {
      service = "http_status:404"
    },
  ]
}
