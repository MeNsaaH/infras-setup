# Cloudflare

Terragrunt stacks for Cloudflare-managed infrastructure. State lives in the
same GCS bucket as the GCP stacks (`mensaah-tfstate`), keyed by the stack's path
under `terraform/` — `cloudflare/arziqi/dns` and so on. Bucket and key scheme are
set once in `terraform/root.hcl`.

Authentication is a `CLOUDFLARE_API_TOKEN` environment variable — no credential
is written to state or to a sops file:

```bash
export CLOUDFLARE_API_TOKEN=...
```

## Stacks

| Stack | Owns |
|---|---|
| `arziqi/inbound-email` | R2 bucket + lifecycle, queues, Email Routing catch-all and address rules |
| `arziqi/dns` | Every DNS record on the `arziqi.com` zone |
| `shared/tunnel` | The `main-gke-tunnel` cloudflared tunnel and its ingress map |

They are separate states on purpose: the tunnel is account-scoped and serves
three domains, DNS changes are frequent and low-risk, and the inbound-email
resources carry a cutover that should be applied on its own.

Not codified anywhere, deliberately:

- **The `flego.io` and `labtime.work` zones.** `flego.io` is the pre-rebrand
  brand and still resolves `api.flego.io` to the production backend; whether it
  keeps answering is a product decision, and codifying it would imply an answer.
- **Managed rulesets and certificate packs** (DDoS L7, Cloudflare Managed Free
  WAF, Normalization). Cloudflare authors these; importing them buys drift, not
  control.
- **Email Routing destination addresses.** Creating one sends a verification
  email to a person.
- **Worker scripts, bindings, and secrets** — wrangler's job, as below.

## `arziqi/inbound-email`

Transport for Arziqi's email-forwarding aliases. Users forward bank alerts to a
per-asset address on `inbound.arziqi.com`; this is what carries that mail to the
application's webhook.

```text
<alias>@inbound.arziqi.com
  -> Cloudflare Email Routing (zone catch-all)
  -> arziqi-inbound-email-worker      raw MIME -> R2, pointer -> Queue
  -> arziqi-inbound-email-consumer    Queue -> parse -> HMAC-signed POST
  -> POST /api/webhooks/inbound-email
```

### What Terraform owns, and what it does not

| Owned here | Owned by wrangler |
|---|---|
| R2 bucket + retention lifecycle | Worker scripts and their bundles |
| Both queues and their retention | Worker bindings (R2, queue producer) |
| Preserved address rules | The queue **consumer** registration |
| The zone catch-all | `ARZIQI_WEBHOOK_SECRET` |

Cloudflare itself owns a third slice: registering a subdomain under Email
Routing makes Cloudflare create and lock that subdomain's MX and SPF records.
`inbound.arziqi.com` is already registered and serving them, so they are
deliberately absent from this stack; a *new* inbound subdomain is registered by
hand under **Compute > Email Service > Email Routing > Settings > Subdomains**.
A precondition on the catch-all refuses to apply while Email Routing is not
enabled and `ready` on the zone.

The queue consumer is deliberately absent: the consumer's `wrangler.toml`
declares `[[queues.consumers]]`, so a `cloudflare_queue_consumer` resource here
would be reverted on every `wrangler deploy` and re-created on every apply.

Worker *code* is not deployable from Terraform either — the consumer bundles
`postal-mime`, and `cloudflare_workers_script` takes an already-bundled module.

### State of the account, audited 2026-08-29

The ARCH-73 prototype left most of this already built by hand, so the first
apply is mostly an adoption rather than a build-out:

| Object | Live state |
|---|---|
| R2 `arziqi-inbound-mails-01` | exists, WEUR/Standard, created 2026-07-28 |
| Queue `arziqi-inbound-email-queue` | exists, 1 producer + 1 consumer, DLQ wired |
| Queue `arziqi-inbound-email-dlq` | exists, idle |
| Workers | both `…-worker` and `…-consumer` deployed |
| Zone catch-all | already targets `arziqi-inbound-email-worker`, **disabled** |
| Address rules | `admin@`, `privacy@`, `legal@` → `legal.arziqi@gmail.com`; `support@` → `support.arziqi@gmail.com`; all enabled |

Two consequences:

- **Nothing depends on the catch-all today** — it is off, and all four apex
  addresses have their own explicit rules that outrank it. Enabling it changes
  delivery for exactly one class of mail: aliases on `inbound.arziqi.com`,
  which today go nowhere.
- **Everything is adopted rather than rebuilt.** All eight live objects,
  including the four apex rules, are declared in `imports.tf` and
  `preserved_forward_rules`, so the zone's routing table is fully described
  here instead of half in code and half in the dashboard. The four rules import
  with no diff: their `name` is left empty because that is what they carry
  today, and `priority` stays 0.

The adoption is declared as `import` blocks rather than out-of-band
`terragrunt import` commands, so the plan reads "will be imported" and is
reviewable in the diff. They are safe to delete once the first apply lands.

Re-audit before applying if the zone may have changed since; the quickest read
is a scratch config using the `cloudflare_email_routing_rules`,
`cloudflare_email_routing_catch_all`, `cloudflare_queues`, and
`cloudflare_workers_scripts` data sources.

### Applied 2026-08-29 — the cutover is live

All three stacks are applied. The first apply adopted the 29 existing objects,
created the R2 lifecycle rule, and flipped the zone catch-all:

```text
~ resource "cloudflare_email_routing_catch_all" "zone" {
    ~ enabled = false -> true
```

Mail to `*@inbound.arziqi.com` now reaches `arziqi-inbound-email-worker`.
To stop delivery again, set `catch_all_enabled = false` and re-apply; nothing is
deleted and already-ingested mail is unaffected.

**The one thing still unverified: the shared secret.** The consumer's
`ARZIQI_WEBHOOK_SECRET` has never been checked against the cluster's
`INBOUND_EMAIL_WEBHOOK_SECRET`. Worker secrets cannot be read back, so a
mismatch shows up only as silence — the backend returns 401, the consumer
retries five times, and each message lands in the dead-letter queue with no
alert. Re-set it if there is any doubt:

```bash
cd workers/inbound-email-consumer   # in the application repository
wrangler secret put ARZIQI_WEBHOOK_SECRET
npm run deploy
```

### Queue retention is already at the ceiling

`message_retention_period` is 86400s on both queues. That is Cloudflare's
maximum, not a default worth raising — the API rejects anything higher:

```text
400  code 100128  message_retention_period must be between 60 and 86400 seconds
```

So a message that exhausts its retries has one day in the DLQ to be noticed and
replayed. Nothing drains that queue automatically, which makes the day the real
recovery window for a forwarded alert that failed to ingest.

### Verify end to end

1. Forward one real bank alert to a provisioned alias.
2. `wrangler tail arziqi-inbound-email-worker` — message accepted, not rejected.
3. An object appears in `arziqi-inbound-mails-01` under `inbound/YYYY/MM/DD/`.
4. `wrangler tail arziqi-inbound-email-consumer` — POST returns 2xx. A `401`
   means `ARZIQI_WEBHOOK_SECRET` does not match the cluster secret.
5. An `inbound_emails` row moves `pending_parser -> parsed`, and the asset
   source flips `pending_verification -> active`.

### Known gaps, deliberately not in this stack

- **No Cloudflare-side alerting.** `cloudflare_notification_policy` has no alert
  type for queue depth, DLQ depth, or Worker error rate, so there is nothing to
  declare. Monitoring has to come from the Workers themselves or from the
  backend side.
- **Nothing drains the DLQ.** Messages park there for manual replay.
- **Postmark is not configured anywhere.** Cloudflare is the only inbound
  transport; the Postmark-shaped payload branch in the webhook handler has no
  sender.

## `arziqi/dns`

All 19 records on the `arziqi.com` zone, one file per purpose:

| File | Records |
|---|---|
| `dns_web.tf` | apex, `www`, `staging` (Netlify), `product-feedback` (Vercel) |
| `dns_api.tf` | `api.arziqi.com` → the cloudflared tunnel |
| `dns_email_routing.tf` | apex + `inbound` MX, `inbound` SPF — **Cloudflare-owned** |
| `dns_email_auth.tf` | apex SPF, DMARC, Cloudflare and Resend DKIM |
| `dns_email_sending.tf` | `send.arziqi.com` MX + SPF (Amazon SES) |
| `dns_verification.tf` | Google site verification |

Each file carries the `import` blocks for its own records, so a group is
reviewable in one place. The whole stack adopts with **19 to import, 0 to add,
0 to change, 0 to destroy** — no record is modified by bringing it under
Terraform.

The records in `dns_email_routing.tf` are declared as a record of what exists,
not as a control surface: Cloudflare creates and re-asserts them from the Email
Routing configuration. Change mail behavior through Email Routing, never by
editing those resources.

Three separate systems are authorized to send as this domain — Cloudflare Email
Routing, Resend (the backend's `RESEND_API_KEY`), and Amazon SES via
`send.arziqi.com`. The `sending_domains` output lists them for deliverability
review; if SES is unused, those two records are the trace to clean up.

## `shared/tunnel`

The cloudflared tunnel that is the **only** public ingress into the GKE
cluster — there is no LoadBalancer or Kubernetes Ingress. Every request to
`api.arziqi.com`, including the inbound-email webhook, arrives through it.

| File | Contents |
|---|---|
| `tunnel.tf` | the tunnel object |
| `ingress.tf` | the ordered hostname → in-cluster service map |

The connector Deployment and its sealed token live in
`infra/kubernetes/apps/cloudflared/main-gke-01`; this stack is the other half.

**Adopt only, never recreate.** The connector token is derived from the tunnel,
so replacing it invalidates the sealed `tunnel-token` Secret and takes the
cluster offline until someone reseals it. The resource carries
`prevent_destroy`, omits `tunnel_secret` (which would force replacement), and
adopts with **2 to import, 0 to change**.

Adding a public hostname takes two changes: a rule in `ingress.tf`, and a CNAME
to `<tunnel_id>.cfargotunnel.com` in whichever zone owns the hostname. The
trailing catch-all rule must stay last — a variable validation enforces it.
