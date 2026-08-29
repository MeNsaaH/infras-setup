output "api_hostname" {
  value       = cloudflare_dns_record.api.name
  description = "Hostname the backend is reachable on, and the target of the inbound-email consumer's ARZIQI_WEBHOOK_URL."
}

output "inbound_mx_hosts" {
  value = sort([
    cloudflare_dns_record.mx_inbound_route1.content,
    cloudflare_dns_record.mx_inbound_route2.content,
    cloudflare_dns_record.mx_inbound_route3.content,
  ])
  description = "Mail exchangers accepting forwarded bank alerts for inbound.arziqi.com."
}

output "sending_domains" {
  value = {
    apex_spf = cloudflare_dns_record.spf_apex.content
    ses      = cloudflare_dns_record.ses_spf.name
    resend   = cloudflare_dns_record.dkim_resend.name
  }
  description = "Every path authorized to send as the domain, for deliverability review."
}
