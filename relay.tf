resource "google_container_registry" "default" {
  location = "us"
}

resource "google_artifact_registry_repository" "relay" {
  location      = var.region
  repository_id = "relay"
  format        = "DOCKER"
}

resource "google_cloudbuild_trigger" "deploy" {
  name = "deploy"
  github {
    owner = "kixelated"
    name  = "mos-rs"
    push {
      branch = "main"
    }
  }

  substitutions = {
    _IMAGE      = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.relay.name}/server"
    _SECRET_CRT = acme_certificate.relay.certificate_pem
    _SECRET_KEY = acme_certificate.relay.private_key_pem
  }

  filename = "cloudbuild.yaml"
}

module "relay" {
  source    = "./relay"
  region    = var.region
  zone      = var.zone
  dns_zone  = google_dns_managed_zone.root.name
  domain    = var.domain
  image     = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.relay.name}/server"
  instances = 2
}
