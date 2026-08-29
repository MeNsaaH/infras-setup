output "tunnel_id" {
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.id
  description = "Target for CNAMEs of the form <tunnel_id>.cfargotunnel.com."
}

output "tunnel_status" {
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.status
  description = "healthy means connectors are attached; down means nothing behind the tunnel is reachable."
}

output "public_hostnames" {
  value = [for rule in var.ingress_rules : rule.hostname if rule.hostname != null]

  description = "Every hostname this tunnel answers for. Each needs a matching CNAME in its own zone."
}
