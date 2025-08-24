variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 11.1"

  project_id   = var.project_id
  network_name = "main"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "subnet-01"
      subnet_ip             = "10.10.0.0/20"
      subnet_region         = var.region
      subnet_private_access = "true"
    },
    {
      subnet_name           = "subnet-02"
      subnet_ip             = "10.10.16.0/20"
      subnet_region         = var.region
      subnet_private_access = "true"
    }
  ]

  secondary_ranges = {
    subnet-01 = [
      {
        range_name    = "subnet-01-secondary-01-pods"
        ip_cidr_range = "172.16.0.0/16" # generous for pods
      },
      {
        range_name    = "subnet-01-secondary-01-services"
        ip_cidr_range = "192.168.0.0/20" # services
      },
    ]

    subnet-02 = []
  }

  # routes = [
  #   {
  #     name              = "egress-internet"
  #     description       = "route through IGW to access internet"
  #     destination_range = "0.0.0.0/0"
  #     tags              = "egress-inet"
  #     next_hop_internet = "true"
  #   }
  # ]
}
