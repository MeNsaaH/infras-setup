# Adoption of resources that already exist in the account.
#
# The ARCH-73 prototype work created the bucket, both queues, and a catch-all
# rule pointing at the Worker by hand, so a first apply without these would try
# to re-create them. Declaring the adoption here rather than as out-of-band
# `terragrunt import` commands keeps it reviewable: the plan reads "will be
# imported", and re-running after a successful apply is a no-op.
#
# These blocks can be deleted once the first apply has landed and the state is
# populated. Ids captured 2026-08-29 from the live account.

import {
  to = cloudflare_r2_bucket.inbound_raw
  id = "f525957c8ee7844a6c5c46efa5936804/arziqi-inbound-mails-01/default"
}

import {
  to = cloudflare_queue.inbound
  id = "f525957c8ee7844a6c5c46efa5936804/1abb8e6732a843a3b62eb0da756ae4cb"
}

import {
  to = cloudflare_queue.inbound_dlq
  id = "f525957c8ee7844a6c5c46efa5936804/ebf75d0826e14d9c9b896fe169eb48e0"
}

# The zone always has exactly one catch-all -- Cloudflare creates it with Email
# Routing -- so this is an adoption, never a creation. It currently targets
# arziqi-inbound-email-worker but is DISABLED; applying this stack with
# catch_all_enabled = true is what actually starts delivery.
import {
  to = cloudflare_email_routing_catch_all.zone
  id = "a8003aca5ce77f92799ec88c7701fb5a"
}

# The apex forwarding rules, created in the dashboard. Adopting them makes the
# zone's routing table fully described by this stack instead of half in code.
import {
  to = cloudflare_email_routing_rule.preserved["admin@arziqi.com"]
  id = "a8003aca5ce77f92799ec88c7701fb5a/d313518fbb0b46da90970df0df4bad6c"
}

import {
  to = cloudflare_email_routing_rule.preserved["privacy@arziqi.com"]
  id = "a8003aca5ce77f92799ec88c7701fb5a/f29f870112074a459ec80f93b78fb621"
}

import {
  to = cloudflare_email_routing_rule.preserved["legal@arziqi.com"]
  id = "a8003aca5ce77f92799ec88c7701fb5a/160c5ba2e987455eb87969aef23df98a"
}

import {
  to = cloudflare_email_routing_rule.preserved["support@arziqi.com"]
  id = "a8003aca5ce77f92799ec88c7701fb5a/c28405ae26b6430a8db7882d6cf15867"
}
