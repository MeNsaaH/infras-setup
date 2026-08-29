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
    cloudflared tunnel that api.<zone_name> is a CNAME to. The tunnel itself and
    its ingress rules live in ../../shared/tunnel; only the DNS side is here.
  EOT
}
