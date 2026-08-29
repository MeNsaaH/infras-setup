# Account-level values for the GCP tree. "Account" is the scope the provider
# bills and grants access by; on GCP that is the project.
#
# State location is not here: terraform/root.hcl derives it from the stack's
# directory path.
locals {
  project_id = "mensaah"
}
