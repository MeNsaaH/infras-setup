# Domain-ownership proofs held by third parties. Each one is a token another
# service issued; deleting a record revokes that service's verification, so
# they are kept even when they look inert.
#
# Google Search Console / Workspace ownership. Also relevant to the pending
# Google OAuth verification for gmail.readonly (see docs/google-verification.md).
resource "cloudflare_dns_record" "google_site_verification" {
  zone_id = var.zone_id
  name    = var.zone_name
  type    = "TXT"
  content = "\"google-site-verification=b4oZCP3WtJzd1z6bD8Ux1OqWlkzWdcR4PoODt_6pcOU\""
  ttl     = 3600
}

import {
  to = cloudflare_dns_record.google_site_verification
  id = "a8003aca5ce77f92799ec88c7701fb5a/f57c61de2378de43cd0128161b3dabe2"
}
