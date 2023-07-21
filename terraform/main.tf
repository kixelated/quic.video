// https://cloud.google.com/shell/docs/cloud-shell-tutorials/deploystack/static-hosting-with-domain

provider "google" {
  project = "quic-video"
  region  = "us-west1"
  zone    = "us-west1-c"
}

variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "domains.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "appengine.googleapis.com",
  ]
}

resource "google_project_service" "all" {
  for_each                   = toset(var.gcp_service_list)
  service                    = each.key
  disable_dependent_services = false
  disable_on_destroy         = false
}
