resource "google_container_registry" "default" {
  location = "us"
}

resource "google_artifact_registry_repository" "relay" {
  location      = var.region
  repository_id = "relay"
  format        = "DOCKER"
}

module "relay" {
  source    = "./relay"
  region    = var.region
  zone      = var.zone
  dns_zone  = google_dns_managed_zone.root.name
  domain    = var.domain
  image     = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.relay.id}/server"
  instances = 2
}
