# The cloudflared tunnel fronting the GKE cluster.
#
# This is the only public ingress into the cluster: there is no LoadBalancer or
# Kubernetes Ingress. Every request to api.arziqi.com -- including the inbound
# email webhook -- arrives through here. Until now it existed only as dashboard
# state, so losing it meant the API was unreachable with nothing in the repo
# describing how to rebuild it.
#
# Adopt only, never recreate: the connector token is derived from the tunnel,
# and a replacement would invalidate the sealed `tunnel-token` Secret in
# infra/kubernetes/apps/cloudflared/main-gke-01, taking the cluster offline
# until it is resealed. `tunnel_secret` is deliberately absent -- it applies to
# locally-managed tunnels, and setting it here would force replacement.

resource "cloudflare_zero_trust_tunnel_cloudflared" "main" {
  account_id = var.account_id
  name       = var.tunnel_name

  # Configuration is held by Cloudflare and delivered to the connector, which
  # is why the Deployment passes only a token and no config file.
  config_src = "cloudflare"

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = cloudflare_zero_trust_tunnel_cloudflared.main
  id = "f525957c8ee7844a6c5c46efa5936804/2b33da82-e272-46ff-bfa7-dca4f1b850a6"
}
