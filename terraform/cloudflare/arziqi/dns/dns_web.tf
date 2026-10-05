# Public web surfaces. All are CNAMEs to third-party hosts, so the record is
# the whole contract with that host -- changing one repoints the site.
#
# ttl = 1 is Cloudflare's "automatic"; it is the only legal value while a
# record is proxied.

resource "cloudflare_dns_record" "apex" {
  zone_id = var.zone_id
  name    = var.zone_name
  type    = "CNAME"
  content = "apex-loadbalancer.netlify.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "www" {
  zone_id = var.zone_id
  name    = "www.${var.zone_name}"
  type    = "CNAME"
  content = "arziqi.netlify.app"
  proxied = true
  ttl     = 1
}

# Still points at the pre-rebrand Netlify site (staging-flego-io). Recorded as
# it stands rather than silently corrected -- see the note in ../../README.md.
resource "cloudflare_dns_record" "staging" {
  zone_id = var.zone_id
  name    = "staging.${var.zone_name}"
  type    = "CNAME"
  content = "staging-flego-io.netlify.app"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "product_feedback" {
  zone_id = var.zone_id
  name    = "product-feedback.${var.zone_name}"
  type    = "CNAME"
  content = "cname.vercel-dns.com"
  proxied = false
  ttl     = 1
}

import {
  to = cloudflare_dns_record.apex
  id = "a8003aca5ce77f92799ec88c7701fb5a/7b8a7ba395fcb4707d335bcf1e2400da"
}

import {
  to = cloudflare_dns_record.www
  id = "a8003aca5ce77f92799ec88c7701fb5a/9fd69b5510a212346f20bfd6c4dad3f0"
}

import {
  to = cloudflare_dns_record.staging
  id = "a8003aca5ce77f92799ec88c7701fb5a/b6583b13aefc242d3f97ecf0b4e70499"
}

import {
  to = cloudflare_dns_record.product_feedback
  id = "a8003aca5ce77f92799ec88c7701fb5a/33f3b5c6d98065c040332c3b13695457"
}
