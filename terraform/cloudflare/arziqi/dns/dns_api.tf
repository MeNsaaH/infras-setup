# The API's entry points: api.arziqi.com resolves to the prod cloudflared tunnel
# and api-staging.arziqi.com to the staging one, each forwarding to azana-web in
# its own GKE cluster. The api record is what makes the production backend
# reachable at all -- including POST /api/webhooks/inbound-email, the endpoint
# the inbound-email Workers deliver to.
#
# The tunnel objects and their ingress rules are in ../../shared/tunnel. They
# are split because tunnels are account-scoped and the staging one also serves
# flego.io and labtime.work, while these records belong to the arziqi.com zone.

resource "cloudflare_dns_record" "api" {
  zone_id = var.zone_id
  name    = "api.${var.zone_name}"
  type    = "CNAME"
  content = "${var.prod_tunnel_id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "api_staging" {
  zone_id = var.zone_id
  name    = "api-staging.${var.zone_name}"
  type    = "CNAME"
  content = "${var.tunnel_id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

import {
  to = cloudflare_dns_record.api
  id = "a8003aca5ce77f92799ec88c7701fb5a/278b31c3b24240af56447bd63b28b335"
}
