# Inbound email transport for Arziqi's forwarding aliases.
#
# Mail flow this stack provisions:
#
#   <alias>@inbound.arziqi.com
#     -> Cloudflare Email Routing (zone catch-all)
#     -> arziqi-inbound-email-worker      (raw MIME -> R2, pointer -> Queue)
#     -> arziqi-inbound-email-consumer    (Queue -> parse -> signed POST)
#     -> POST /api/webhooks/inbound-email on the Arziqi backend
#
# Split of ownership, so Terraform and wrangler never fight over the same
# object: Terraform owns the account-level resources and the routing rules;
# wrangler owns the Worker scripts, their bindings, the queue *consumer*
# registration ([[queues.consumers]]), and ARZIQI_WEBHOOK_SECRET. Adding
# cloudflare_queue_consumer here would collide with the consumer's
# wrangler.toml on every deploy.

data "cloudflare_zones" "primary" {
  account = {
    id = var.account_id
  }
  name   = var.zone_name
  status = "active"
}

locals {
  zone_id = data.cloudflare_zones.primary.result[0].id
}

# ── Durable storage for raw inbound MIME ─────────────────────────────────────

resource "cloudflare_r2_bucket" "inbound_raw" {
  account_id    = var.account_id
  name          = var.raw_bucket_name
  location      = var.raw_bucket_location
  storage_class = "Standard"
}

# The Email Worker writes raw MIME here and rejects the message (SMTP temp
# failure) if the write fails, so the sender retries rather than the mail being
# silently dropped. Nothing else reads these objects once the consumer has
# posted the parsed payload, so they expire.
#
# Note: the provider cannot destroy this resource. Removing it from the
# configuration drops it from state and leaves the rule live on the bucket;
# retiring the retention rule means editing it here or deleting it in R2.
resource "cloudflare_r2_bucket_lifecycle" "inbound_raw" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.inbound_raw.name

  rules = [{
    id      = "expire-raw-inbound-mime"
    enabled = true

    conditions = {
      prefix = var.raw_object_prefix
    }

    delete_objects_transition = {
      condition = {
        type    = "Age"
        max_age = var.raw_retention_days * 24 * 60 * 60
      }
    }

    # A multipart upload interrupted by a Worker eviction would otherwise
    # linger and bill indefinitely.
    abort_multipart_uploads_transition = {
      condition = {
        type    = "Age"
        max_age = 24 * 60 * 60
      }
    }
  }]
}

# ── Queues between the two Workers ───────────────────────────────────────────

resource "cloudflare_queue" "inbound" {
  account_id = var.account_id
  queue_name = var.queue_name

  settings = {
    message_retention_period = var.queue_message_retention_seconds
  }
}

# The consumer retries a failed delivery (max_retries = 5 in its wrangler.toml)
# and then parks the message here. Nothing drains this queue automatically:
# messages wait for a human to investigate and replay, which is why its
# retention matches the main queue.
resource "cloudflare_queue" "inbound_dlq" {
  account_id = var.account_id
  queue_name = var.dead_letter_queue_name

  settings = {
    message_retention_period = var.queue_message_retention_seconds
  }
}

# ── Email Routing ────────────────────────────────────────────────────────────

# Email Routing enablement is intentionally NOT a resource here.
#
# Registering a subdomain under Email Routing makes Cloudflare create and own
# the subdomain's MX and SPF records itself ("Cloudflare adds the required DNS
# records to the subdomain"), so declaring them -- or the zone's email routing
# settings -- as Terraform resources would fight Cloudflare's own management of
# records it locks. inbound.arziqi.com is already registered and serving those
# records; a new inbound subdomain is registered once, by hand, under
# Compute > Email Service > Email Routing > Settings > Subdomains.
#
# Read instead, so the catch-all below can refuse to apply against a zone where
# Email Routing is off or misconfigured rather than pointing a rule at a
# transport that delivers nothing.
data "cloudflare_email_routing_settings" "zone" {
  zone_id = local.zone_id
}

# Explicit address rules always win over the catch-all. Anything that must keep
# being delivered to a human mailbox after the cutover belongs here; see the
# preserved_forward_rules variable for how to enumerate the zone's current
# rules before the first apply.
resource "cloudflare_email_routing_rule" "preserved" {
  for_each = var.preserved_forward_rules

  zone_id  = local.zone_id
  name     = each.value.name
  enabled  = true
  priority = each.value.priority

  matchers = [{
    type  = "literal"
    field = "to"
    value = each.key
  }]

  actions = [{
    type  = "forward"
    value = each.value.destinations
  }]
}

# Everything the explicit rules did not match is handed to the Email Worker,
# which accepts mail for inbound_domain and rejects the rest at the edge.
#
# There is exactly one catch-all per zone (its id *is* the zone id), so this
# resource replaces whatever the zone's catch-all does today. Review the plan
# against the live rule before applying.
resource "cloudflare_email_routing_catch_all" "zone" {
  zone_id = local.zone_id
  name    = "Arziqi inbound bank-alert ingestion"
  enabled = var.catch_all_enabled

  matchers = [{
    type = "all"
  }]

  actions = [{
    type  = "worker"
    value = [var.worker_script_name]
  }]

  # Explicit preservation rules must exist before the catch-all stops
  # forwarding mail they are meant to keep delivering.
  depends_on = [cloudflare_email_routing_rule.preserved]

  # A precondition, not a check block: check assertions only emit warnings,
  # and silently repointing the zone's mail at a disabled transport is not a
  # warning.
  lifecycle {
    precondition {
      condition = (
        data.cloudflare_email_routing_settings.zone.enabled &&
        data.cloudflare_email_routing_settings.zone.status == "ready"
      )
      error_message = "Email Routing on ${var.zone_name} is not enabled and ready (status '${data.cloudflare_email_routing_settings.zone.status}'); the catch-all would deliver nowhere."
    }
  }
}
