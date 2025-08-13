terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
    }
  }

  backend "gcs" {
    bucket = "quic-video-tfstate"
    prefix = "terraform/state"
  }

  required_version = ">= 1.5"
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "domains.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iamcredentials.googleapis.com",
  ]
}

resource "google_project_service" "all" {
  for_each                   = toset(var.gcp_service_list)
  service                    = each.key
  disable_dependent_services = false
  disable_on_destroy         = false
}

data "google_project" "current" {
  project_id = var.project
}
