# Sender authentication for arziqi.com: who may send as the domain, how
# receivers verify it, and what to do when verification fails.
#
# The apex SPF authorizes two senders: Cloudflare Email Routing (which
# re-sends forwarded mail) and Google Workspace. Anything that starts sending
# as @arziqi.com has to be added here or it lands in spam.

resource "cloudflare_dns_record" "spf_apex" {
  zone_id = var.zone_id
  name    = var.zone_name
  type    = "TXT"
  content = "\"v=spf1 include:_spf.mx.cloudflare.net include:_spf.google.com ~all\""
  ttl     = 1
}

# p=none only monitors -- it asks receivers to report, never to reject or
# quarantine a forgery. Tightening it to quarantine/reject is SEC-2 (#626) and
# is deliberately not done here: that is a deliverability change needing its
# own rollout, not a side effect of importing DNS.
resource "cloudflare_dns_record" "dmarc" {
  zone_id = var.zone_id
  name    = "_dmarc.${var.zone_name}"
  type    = "TXT"
  content = "\"v=DMARC1; p=none; rua=mailto:dmarc@arziqi.com; fo=1\""
  ttl     = 1
}

# DKIM key Cloudflare Email Routing signs forwarded mail with. Cloudflare owns
# this record; see the warning in dns_email_routing.tf.
resource "cloudflare_dns_record" "dkim_cloudflare" {
  zone_id = var.zone_id
  name    = "cf2024-1._domainkey.${var.zone_name}"
  type    = "TXT"
  content = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\""
  ttl     = 1
}

# DKIM key for Resend, which sends the product's transactional mail
# (RESEND_API_KEY in the backend SealedSecret).
resource "cloudflare_dns_record" "dkim_resend" {
  zone_id = var.zone_id
  name    = "resend._domainkey.${var.zone_name}"
  type    = "TXT"
  content = "\"p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDeo7Zsf/yEljjCi87BJ4OBTKJeVBt+/VUpNsKukIPGB46BUydd9ZpIePjIsPBLAKMk4KmsNT2Zw/J34+Fo+fMgjPabrhPHRT3V4PX2tSOfWJe6oAF4imyiagd9iH3FR7Be1FRmz3eq4uleP3yqA+O6cSn6f7bXoIjLv6Za7R256QIDAQAB\""
  ttl     = 3600
}

import {
  to = cloudflare_dns_record.spf_apex
  id = "a8003aca5ce77f92799ec88c7701fb5a/c28d2c4f9b8df06a0dead6c0b42f7292"
}

import {
  to = cloudflare_dns_record.dmarc
  id = "a8003aca5ce77f92799ec88c7701fb5a/abf746b24c3fdaf271ccc642d7ae97c0"
}

import {
  to = cloudflare_dns_record.dkim_cloudflare
  id = "a8003aca5ce77f92799ec88c7701fb5a/ca9473a11e02c991dc179da2600edc35"
}

import {
  to = cloudflare_dns_record.dkim_resend
  id = "a8003aca5ce77f92799ec88c7701fb5a/74023ea3e3799a63c8c76d4cef86a45c"
}
