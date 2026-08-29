variable "account_id" {
  type        = string
  description = "Cloudflare account owning the tunnel."
}

variable "tunnel_id" {
  type        = string
  description = "Existing cloudflared tunnel to adopt. Tunnels cannot be recreated without re-issuing the connector token, so this stack only ever adopts."
}

variable "tunnel_name" {
  type        = string
  description = "Tunnel name as registered with Cloudflare. Renaming does not reissue the token, but it does change what the dashboard and `cloudflared` logs show."
}

variable "ingress_rules" {
  type = list(object({
    hostname = optional(string)
    service  = string

    # Per-hostname connection overrides. Cloudflare distinguishes "no overrides
    # object" (null) from "an overrides object with nothing set" ({}), and the
    # adopted config uses the latter on one rule, so the distinction has to be
    # expressible or adoption shows a spurious diff. Typed empty because no
    # rule currently sets a field; widen it when one needs to.
    origin_request = optional(object({}))
  }))
  description = <<-EOT
    Ordered hostname -> origin map. cloudflared matches top down and the LAST
    rule must be a catch-all with no hostname, or Cloudflare rejects the
    configuration.

    Services are in-cluster URLs resolved by the cloudflared pods running in
    GKE (infra/kubernetes/apps/cloudflared), so they are Kubernetes DNS names,
    not public addresses.
  EOT

  validation {
    condition     = length(var.ingress_rules) > 0 && try(var.ingress_rules[length(var.ingress_rules) - 1].hostname, null) == null
    error_message = "The last ingress rule must be the catch-all: a service with no hostname."
  }
}
