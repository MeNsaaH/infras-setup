# ⚠ Cloudflare Email Routing creates and owns these records.
#
# They are declared here as a record of what the zone carries, NOT as a control
# surface. Enabling Email Routing on the apex and on the inbound subdomain is
# what produced them, and Cloudflare re-asserts them; the dashboard shows them
# as managed. Do not edit these to change mail behavior -- change Email Routing
# itself (../inbound-email for the catch-all and rules, the dashboard for
# subdomain registration) and let it update the records.
#
# The values are pinned so that drift shows up in a plan: if Cloudflare ever
# rotates the MX hosts or the DKIM key, this stack goes red and someone looks.

# ── Apex MX: mail for arziqi.com ─────────────────────────────────────────────

resource "cloudflare_dns_record" "mx_apex_route1" {
  zone_id  = var.zone_id
  name     = var.zone_name
  type     = "MX"
  content  = "route1.mx.cloudflare.net"
  priority = 27
  ttl      = 1
}

resource "cloudflare_dns_record" "mx_apex_route2" {
  zone_id  = var.zone_id
  name     = var.zone_name
  type     = "MX"
  content  = "route2.mx.cloudflare.net"
  priority = 79
  ttl      = 1
}

resource "cloudflare_dns_record" "mx_apex_route3" {
  zone_id  = var.zone_id
  name     = var.zone_name
  type     = "MX"
  content  = "route3.mx.cloudflare.net"
  priority = 71
  ttl      = 1
}

# ── inbound.arziqi.com MX: the forwarding aliases ────────────────────────────
#
# These are what carry a user's forwarded bank alert to the Email Worker.
# database.InboundEmailDomain mints addresses on this subdomain.

resource "cloudflare_dns_record" "mx_inbound_route1" {
  zone_id  = var.zone_id
  name     = "inbound.${var.zone_name}"
  type     = "MX"
  content  = "route1.mx.cloudflare.net"
  priority = 27
  ttl      = 1
}

resource "cloudflare_dns_record" "mx_inbound_route2" {
  zone_id  = var.zone_id
  name     = "inbound.${var.zone_name}"
  type     = "MX"
  content  = "route2.mx.cloudflare.net"
  priority = 79
  ttl      = 1
}

resource "cloudflare_dns_record" "mx_inbound_route3" {
  zone_id  = var.zone_id
  name     = "inbound.${var.zone_name}"
  type     = "MX"
  content  = "route3.mx.cloudflare.net"
  priority = 71
  ttl      = 1
}

resource "cloudflare_dns_record" "spf_inbound" {
  zone_id = var.zone_id
  name    = "inbound.${var.zone_name}"
  type    = "TXT"
  content = "\"v=spf1 include:_spf.mx.cloudflare.net include:_spf.google.com ~all\""
  ttl     = 1
}

import {
  to = cloudflare_dns_record.mx_apex_route1
  id = "a8003aca5ce77f92799ec88c7701fb5a/bcb023acb36d9e09a61a72ec3dbae85b"
}

import {
  to = cloudflare_dns_record.mx_apex_route2
  id = "a8003aca5ce77f92799ec88c7701fb5a/5e2aa2db825b09731ce12b96655743be"
}

import {
  to = cloudflare_dns_record.mx_apex_route3
  id = "a8003aca5ce77f92799ec88c7701fb5a/afe4ec1c4445a7e2a1ad6dab13070497"
}

import {
  to = cloudflare_dns_record.mx_inbound_route1
  id = "a8003aca5ce77f92799ec88c7701fb5a/2ad2c7314bfcd8cf7efa8da8ac94a8d1"
}

import {
  to = cloudflare_dns_record.mx_inbound_route2
  id = "a8003aca5ce77f92799ec88c7701fb5a/98d25ebd8f0ed267019e2d42230d791e"
}

import {
  to = cloudflare_dns_record.mx_inbound_route3
  id = "a8003aca5ce77f92799ec88c7701fb5a/537529d4d973f000792bb09cd9157e15"
}

import {
  to = cloudflare_dns_record.spf_inbound
  id = "a8003aca5ce77f92799ec88c7701fb5a/9b4e0e875941b2ec2df99f21563c4006"
}
