terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.24"
    }
  }
}

# CLOUDFLARE_API_TOKEN from the environment; needs Zone | DNS | Edit and
# Zone | Zone Settings | Edit on arziqi.com. See ../../README.md.
provider "cloudflare" {}
