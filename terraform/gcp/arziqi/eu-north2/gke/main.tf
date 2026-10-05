variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc" {}

data "google_client_config" "default" {}

locals {
  vpc = jsondecode(var.vpc)
}

module "gke" {
  source                               = "terraform-google-modules/kubernetes-engine/google"
  version                              = "~> 45.0"
  project_id                           = var.project_id
  name                                 = "prod-gke-01"
  regional                             = false
  region                               = var.region
  zones                                = ["${var.region}-a"]
  network                              = local.vpc.network_name
  subnetwork                           = local.vpc.subnets_names[0]
  ip_range_pods                        = local.vpc.subnets_secondary_ranges[0][0].range_name
  ip_range_services                    = local.vpc.subnets_secondary_ranges[0][1].range_name
  remove_default_node_pool             = true
  http_load_balancing                  = false
  network_policy                       = false
  node_metadata                        = "GCE_METADATA"
  logging_service                      = "none"
  monitoring_service                   = "none"
  horizontal_pod_autoscaling           = false
  # null lets logging_service/monitoring_service apply; Managed Prometheus then
  # defaults on and is disabled out of band (gcloud --monitoring=NONE, --disable-managed-prometheus).
  monitoring_enable_managed_prometheus = null

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "e2-medium"
      node_locations     = "${var.region}-a"
      min_count          = 1
      max_count          = 2
      local_ssd_count    = 0
      spot               = true
      disk_size_gb       = 15
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      logging_variant    = "DEFAULT"
      auto_repair        = true
      auto_upgrade       = true
      initial_node_count = 0
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}


