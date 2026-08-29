# Hostname -> in-cluster service routing for the tunnel.
#
# Order matters: cloudflared evaluates top down and stops at the first match,
# and the trailing catch-all is mandatory. Adding a public hostname takes two
# changes -- a rule here, and a CNAME to <tunnel_id>.cfargotunnel.com in the
# zone that owns the hostname (arziqi.com records live in ../../arziqi/dns).

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "main" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id
  source     = "cloudflare"

  config = {
    ingress = var.ingress_rules
  }
}

import {
  to = cloudflare_zero_trust_tunnel_cloudflared_config.main
  id = "f525957c8ee7844a6c5c46efa5936804/2b33da82-e272-46ff-bfa7-dca4f1b850a6"
}
