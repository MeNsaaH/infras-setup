# The API's entry point: api.arziqi.com resolves to the cloudflared tunnel,
# which forwards to azana-web in the GKE cluster. This one record is what makes
# the backend reachable at all -- including POST /api/webhooks/inbound-email,
# the endpoint the inbound-email Workers deliver to.
#
# The tunnel object and its ingress rules are in ../../shared/tunnel. They are
# split because the tunnel is account-scoped and also serves flego.io and
# labtime.work, while this record belongs to the arziqi.com zone.

resource "cloudflare_dns_record" "api" {
  zone_id = var.zone_id
  name    = "api.${var.zone_name}"
  type    = "CNAME"
  content = "${var.tunnel_id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

import {
  to = cloudflare_dns_record.api
  id = "a8003aca5ce77f92799ec88c7701fb5a/278b31c3b24240af56447bd63b28b335"
}
