locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  account_id = local.account_vars.locals.account_id
  zone_name  = local.account_vars.locals.zone_name

  # Must stay in lockstep with database.InboundEmailDomain (backend) and
  # ALLOWED_RECIPIENT_DOMAIN (workers/inbound-email-worker/wrangler.toml).
  inbound_domain = "inbound.arziqi.com"

  # Deployed by wrangler, not by this stack.
  worker_script_name = "arziqi-inbound-email-worker"

  # Names are fixed by the wrangler bindings that consume them.
  raw_bucket_name        = "arziqi-inbound-mails-01"
  queue_name             = "arziqi-inbound-email-queue"
  dead_letter_queue_name = "arziqi-inbound-email-dlq"

  raw_retention_days = 30

  # Set to false to provision the storage/queue/DNS plumbing without changing
  # mail delivery, then flip to true as a separate, single-resource apply.
  catch_all_enabled = true

  # The zone's apex forwarding rules, adopted from the dashboard so the routing
  # table is fully described here rather than half in code and half by hand.
  # Explicit rules outrank the catch-all, so these keep delivering to their
  # mailboxes after the cutover. Destinations are already verified in the
  # account; this stack does not manage cloudflare_email_routing_address.
  preserved_forward_rules = {
    "admin@arziqi.com"   = { destinations = ["legal.arziqi@gmail.com"] }
    "privacy@arziqi.com" = { destinations = ["legal.arziqi@gmail.com"] }
    "legal@arziqi.com"   = { destinations = ["legal.arziqi@gmail.com"] }
    "support@arziqi.com" = { destinations = ["support.arziqi@gmail.com"] }
  }
}
