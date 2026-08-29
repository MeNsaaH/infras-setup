# Shared Terragrunt root for every stack under terraform/.
#
# Stacks include it with `find_in_parent_folders("root.hcl")`, which walks up
# until it lands here, so adding a provider tree needs no root of its own.
#
# State lives in one bucket for the whole repository, keyed by the stack's path
# under terraform/ -- gcp/mensaah/eu-north1/argocd, cloudflare/arziqi/dns. The
# directory a person cd's into and the object in GCS are then the same string,
# so a stack is findable in the bucket without consulting any config.
#
# path_relative_to_include() resolves against the directory holding this root,
# which is why the key needs no per-tree contribution: adding a provider tree
# requires nothing here, and account.hcl is left to describe only the provider
# scope its own stacks read.
#
# Moving or renaming a stack directory changes its key and orphans its state.
# Copy the object to the new key first, then run `terragrunt init` and let it
# migrate.
locals {
  state_bucket = "mensaah-tfstate"
  state_prefix = path_relative_to_include()
}

engine {
  source  = "github.com/gruntwork-io/terragrunt-engine-opentofu"
  version = "v0.0.22"
}

# Bounds, not pins: .tool-versions holds the exact versions tenv installs.
#
# Keep these in step with it. tenv searches upward from the directory it runs
# in and takes the first version source it meets, so a constraint here wins
# over a .tool-versions further up the tree. A constraint that excludes the
# pinned version sends tenv to the GitHub releases API to hunt for an older
# build, where an unauthenticated run is rate-limited and simply fails.
terraform_version_constraint = "~> 1.12"

terragrunt_version_constraint = "~> 1.1"

generate "remote_state" {
  path      = "backend.terragrunt.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "gcs" {
    bucket = "${local.state_bucket}"
    prefix = "${local.state_prefix}"
  }
}
EOF
}
