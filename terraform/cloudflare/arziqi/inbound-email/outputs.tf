output "zone_id" {
  value       = local.zone_id
  description = "Zone whose Email Routing configuration this stack manages. Needed for the import commands in README.md."
}

output "inbound_domain" {
  value       = var.inbound_domain
  description = "Subdomain the backend mints aliases on (database.InboundEmailDomain)."
}

output "raw_bucket_name" {
  value       = cloudflare_r2_bucket.inbound_raw.name
  description = "R2 bucket the Email Worker writes raw MIME to."
}

output "queue_names" {
  value = {
    main = cloudflare_queue.inbound.queue_name
    dlq  = cloudflare_queue.inbound_dlq.queue_name
  }
  description = "Queue names that must match the wrangler configs."
}

output "catch_all_target" {
  value = {
    worker  = var.worker_script_name
    enabled = var.catch_all_enabled
  }
  description = "Where unmatched mail on the zone is delivered."
}

output "preserved_addresses" {
  value       = sort(keys(var.preserved_forward_rules))
  description = "Addresses that keep forwarding to a mailbox instead of reaching the Worker."
}
