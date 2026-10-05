variable "account_id" {
  type        = string
  description = "Cloudflare account that owns the R2 bucket, queues, and Workers."
}

variable "zone_name" {
  type        = string
  description = "Zone whose Email Routing catch-all delivers inbound mail to the Worker."
}

variable "inbound_domain" {
  type        = string
  description = <<-EOT
    Subdomain that receives forwarding aliases. Must match
    database.InboundEmailDomain in the backend and ALLOWED_RECIPIENT_DOMAIN in
    workers/inbound-email-worker/wrangler.toml, or the Worker rejects every
    message at the edge.
  EOT

  validation {
    condition     = endswith(var.inbound_domain, var.zone_name)
    error_message = "inbound_domain must be inside zone_name; Email Routing only routes addresses in its own zone."
  }
}

variable "worker_script_name" {
  type        = string
  description = <<-EOT
    Name of the deployed Email Worker that the catch-all hands messages to.
    Terraform does not deploy the script: wrangler owns the bundle, its
    bindings, and its secrets. The script must already exist or the catch-all
    apply fails.
  EOT

  validation {
    condition     = length(trimspace(var.worker_script_name)) > 0
    error_message = "worker_script_name must name a deployed Worker."
  }
}

variable "raw_bucket_name" {
  type        = string
  description = "R2 bucket holding raw inbound MIME. Must match RAW_EMAIL_BUCKET / RAW_EMAIL_BUCKET_NAME in both wrangler.toml files."
}

variable "raw_bucket_location" {
  type        = string
  default     = "weur"
  description = "Best-effort R2 placement hint. Only honored when the bucket is first created; ignored on import."

  validation {
    condition     = contains(["apac", "eeur", "enam", "weur", "wnam", "oc"], var.raw_bucket_location)
    error_message = "raw_bucket_location must be one of apac, eeur, enam, weur, wnam, oc."
  }
}

variable "raw_retention_days" {
  type        = number
  default     = 30
  description = <<-EOT
    How long raw MIME is kept in R2 before the lifecycle rule deletes it. Raw
    mail is replay/audit evidence, not the system of record: the parsed payload
    the backend stores is what the processor reads. Keep this short — CRIT-1
    (#647) committed to minimizing raw email storage.
  EOT

  validation {
    condition     = var.raw_retention_days >= 1 && var.raw_retention_days <= 365
    error_message = "raw_retention_days must be between 1 and 365."
  }
}

variable "raw_object_prefix" {
  type        = string
  default     = "inbound/"
  description = "Key prefix the Email Worker writes under (buildRawEmailKey). Scopes the retention rule."
}

variable "queue_name" {
  type        = string
  description = "Queue the Email Worker produces to. Must match [[queues.producers]] and [[queues.consumers]] in the wrangler configs."
}

variable "dead_letter_queue_name" {
  type        = string
  description = "Dead-letter queue for messages the consumer could not deliver. Must match dead_letter_queue in the consumer wrangler config."
}

variable "queue_message_retention_seconds" {
  type        = number
  default     = 86400
  description = <<-EOT
    How long an unconsumed message survives. Set to Cloudflare's maximum, which
    is also what both queues already carry: a message that fails every retry
    has one day to be noticed and replayed from the dead-letter queue before it
    is gone. Nothing drains the DLQ automatically, so this is the real window
    for recovering a forwarded alert that failed to ingest.
  EOT

  validation {
    condition     = var.queue_message_retention_seconds >= 60 && var.queue_message_retention_seconds <= 86400
    error_message = "queue_message_retention_seconds must be between 60 and 86400 (1 day) -- the Cloudflare Queues API rejects anything higher with 100128."
  }
}

variable "catch_all_enabled" {
  type        = bool
  default     = true
  description = <<-EOT
    Whether the zone catch-all is active. Cloudflare only supports a catch-all
    at zone level, never per subdomain, so enabling this routes every address
    on the zone that no explicit rule matches to the Worker — and the Worker
    rejects anything not addressed to inbound_domain. Every apex address that
    must keep being delivered has to appear in preserved_forward_rules first.
  EOT
}

variable "preserved_forward_rules" {
  type = map(object({
    destinations = list(string)
    priority     = optional(number, 0)
    # Cloudflare's rule "name" is the free-text description shown in the
    # dashboard. It defaults to empty because that is what the adopted rules
    # carry; setting one here renames the rule in the UI.
    name = optional(string, "")
  }))
  default     = {}
  description = <<-EOT
    Explicit address rules that must keep forwarding after the catch-all is
    pointed at the Worker, keyed by the receiving address. Explicit rules take
    precedence over the catch-all.

    Rules that already exist in the zone are not managed by this stack and are
    left alone, so the cutover only changes delivery for addresses that rely on
    the catch-all today. Those are the ones to list here — omitting one means
    mail to it reaches the Worker, which rejects anything outside
    inbound_domain.

    Destination addresses must already be verified in the Cloudflare account —
    this stack deliberately does not manage cloudflare_email_routing_address,
    because creating one sends a verification email to a human.

    Populate this from the zone's current routing rules BEFORE the first apply:
      curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        "https://api.cloudflare.com/client/v4/zones/<zone_id>/email/routing/rules"
  EOT
}
