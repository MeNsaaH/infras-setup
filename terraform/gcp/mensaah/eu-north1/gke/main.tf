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
  version                              = "~>38.0"
  project_id                           = var.project_id
  name                                 = "main-gke-01"
  regional                             = false
  region                               = var.region
  zones                                = ["${var.region}-a"]
  network                              = local.vpc.network_name
  subnetwork                           = local.vpc.subnets_names[0]
  ip_range_pods                        = local.vpc.subnets_secondary_ranges[0][0].range_name
  ip_range_services                    = local.vpc.subnets_secondary_ranges[0][1].range_name
  http_load_balancing                  = true
  network_policy                       = true
  horizontal_pod_autoscaling           = false
  monitoring_enable_managed_prometheus = false

  # workload_identity_config = {
  #   workload_pool = "${var.project_id}.svc.id.goog"
  # }
  # kubernetes_version         = "1.33.2-gke.1240000"

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
      # service_account    = "project-service-account@mensaah.iam.gserviceaccount.com"
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}


