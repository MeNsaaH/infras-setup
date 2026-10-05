terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.24"
    }
  }
}

# CLOUDFLARE_API_TOKEN from the environment; needs Account | Cloudflare Tunnel |
# Edit. See ../../README.md.
provider "cloudflare" {}
