# send.arziqi.com -- a delegated sending subdomain on Amazon SES, with its own
# MX (for bounce/complaint feedback) and its own SPF.
#
# Note this is a third sending path alongside Resend (transactional mail from
# the backend) and Cloudflare Email Routing (forwarding). If SES is not
# actually in use, these two records are the trace to clean up.

resource "cloudflare_dns_record" "ses_mx" {
  zone_id  = var.zone_id
  name     = "send.${var.zone_name}"
  type     = "MX"
  content  = "feedback-smtp.eu-west-1.amazonses.com"
  priority = 10
  ttl      = 3600
}

resource "cloudflare_dns_record" "ses_spf" {
  zone_id = var.zone_id
  name    = "send.${var.zone_name}"
  type    = "TXT"
  content = "\"v=spf1 include:amazonses.com ~all\""
  ttl     = 3600
}

import {
  to = cloudflare_dns_record.ses_mx
  id = "a8003aca5ce77f92799ec88c7701fb5a/629e642a15990b962f9f351445db1232"
}

import {
  to = cloudflare_dns_record.ses_spf
  id = "a8003aca5ce77f92799ec88c7701fb5a/5b568b7cc4e83b5b1b9e35124741ec41"
}
