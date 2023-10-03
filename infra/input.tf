variable "project" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

variable "email" {
  description = "Your email address, used for LetsEncrypt"
}

variable "domain" {
  description = "domain name"
}

# Too complicated to specify via flags, so do it here.
locals {
  regions = {
    us-central = { # Iowa
      region = "us-central1"
      zone   = "us-central1-a",
      count  = 2
    },
    europe-west = { # Netherlands
      region = "europe-west4",
      zone   = "europe-west4-b",
      count  = 2
    },
    asia-southeast = { # Singapore
      region = "asia-southeast1",
      zone   = "asia-southeast1-c", // T2A not available in -a
      count  = 2
    }
  }

  regions_flat = merge([
    for name, val in local.regions : {
      for i in range(val.count) :
      "${name}-${i}" => {
        region = val.region,
        zone   = val.zone,
      }
    }
  ]...)
}
