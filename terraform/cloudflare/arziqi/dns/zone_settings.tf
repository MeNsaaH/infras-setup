# Cloudflare's default is TLS 1.0; 1.0 and 1.1 are deprecated.
resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = var.zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}
