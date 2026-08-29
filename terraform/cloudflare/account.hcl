locals {
  # Cloudflare account that owns the Workers, R2 buckets, and Queues, and the
  # arziqi.com zone. This is the same account id the inbound-email Workers
  # deploy into (workers/*/wrangler.toml in the application repository).
  account_id = "f525957c8ee7844a6c5c46efa5936804"

  # Primary zone. Email Routing catch-all rules are zone-level, so the aliases
  # under inbound.arziqi.com are routed by this zone's catch-all.
  zone_name = "arziqi.com"

  # Resolved once here rather than looked up per stack, so a stack that manages
  # DNS does not need account-wide zone-list permission.
  arziqi_zone_id = "a8003aca5ce77f92799ec88c7701fb5a"

  # cloudflared tunnel fronting the GKE cluster. Its connector Deployment and
  # sealed token live in infra/kubernetes/apps/cloudflared.
  main_tunnel_id = "2b33da82-e272-46ff-bfa7-dca4f1b850a6"

}
