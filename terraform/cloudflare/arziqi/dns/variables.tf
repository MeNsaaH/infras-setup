variable "zone_id" {
  type        = string
  description = "arziqi.com zone."
}

variable "zone_name" {
  type        = string
  description = "Apex domain, used to build record names."
}

variable "tunnel_id" {
  type        = string
  description = <<-EOT
    Staging cloudflared tunnel that api-staging.<zone_name> is a CNAME to. The
    tunnels and their ingress rules live in ../../shared/tunnel; only the DNS
    side is here.
  EOT
}

variable "prod_tunnel_id" {
  type        = string
  description = "cloudflared tunnel for prod-gke-01 that api.<zone_name> is a CNAME to."
}
