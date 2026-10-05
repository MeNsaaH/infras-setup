terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.24"
    }
  }
}

# Authentication comes from the CLOUDFLARE_API_TOKEN environment variable so no
# credential is written to state or to a sops file. The token needs:
#   Account | Workers R2 Storage      | Edit
#   Account | Queues                  | Edit
#   Account | Workers Scripts         | Edit
#   Zone    | Zone                    | Read
#   Zone    | Zone Settings           | Edit   (Email Routing enablement)
#   Zone    | Email Routing Rules     | Edit
provider "cloudflare" {}
