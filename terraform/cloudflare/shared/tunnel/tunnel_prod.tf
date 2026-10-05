# Created here, unlike main-gke-tunnel which was adopted. Its connector token is
# sealed into infra/kubernetes/apps/cloudflared/arziqi-prod-gke-01 by hand.
resource "cloudflare_zero_trust_tunnel_cloudflared" "prod" {
  account_id = var.account_id
  name       = var.prod_tunnel_name
  config_src = "cloudflare"

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "prod" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.prod.id
  source     = "cloudflare"

  config = {
    ingress = var.prod_ingress_rules
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "prod" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.prod.id
}
