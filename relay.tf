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
    name  = "moq-rs"
    push {
      branch = "^main$"
    }
  }

  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "-t", "$_IMAGE", "."]
    }

    artifacts {
      images = ["$_IMAGE"]
    }
  }

  substitutions = {
    _IMAGE = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.relay.name}/server"
  }

}

module "relay" {
  source    = "./relay"
  region    = var.region
  zone      = var.zone
  dns_zone  = google_dns_managed_zone.root.name
  domain    = "relay.${var.domain}"
  image     = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.relay.name}/server"
  email     = var.email
  crt       = acme_certificate.relay.certificate_pem
  key       = acme_certificate.relay.private_key_pem
  instances = 2
}
