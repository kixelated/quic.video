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

resource "google_compute_instance" "relay" {
  for_each = local.regions_flat

  name         = "relay-${each.key}"
  machine_type = "t2a-standard-1"
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-arm64-stable"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.relay[each.key].address
    }
  }

  metadata = {
    # cloud-init template
    user-data = templatefile("${path.module}/relay.yml.tpl", {
      image = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.relay.name}/server"
      email = var.email
      crt   = acme_certificate.relay.certificate_pem
      key   = acme_certificate.relay.private_key_pem
    })
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  # For the firewall
  tags = ["relay"]

  lifecycle {
    # There seems to be a terraform bug causing this to be recreated on every apply
    ignore_changes = [boot_disk]
  }

  depends_on = [null_resource.recreate_trigger]
}

# Recreate the instance if the cloud-init script changes
resource "null_resource" "recreate_trigger" {
  triggers = {
    user_data_hash = sha256(templatefile("${path.module}/relay.yml.tpl", {
      image = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.relay.name}/server"
      email = var.email
      crt   = acme_certificate.relay.certificate_pem
      key   = acme_certificate.relay.private_key_pem
    }))
  }
}

resource "google_compute_address" "relay" {
  for_each = local.regions_flat

  name   = "relay-${each.key}"
  region = each.value.region
}

resource "google_dns_record_set" "relay" {
  for_each = local.regions_flat

  name         = "${each.key}.relay.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.root.name
  rrdatas      = [google_compute_address.relay[each.key].address]
}

# Allow UDP 443
resource "google_compute_firewall" "relay" {
  name    = "relay"
  network = "default"

  # TODO only allow for internal health checks
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  allow {
    protocol = "udp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["relay"]
}

# We must use a legacy health check for the UDP load balancer
resource "google_compute_http_health_check" "relay" {
  name               = "relay"
  request_path       = "/health"
  check_interval_sec = 5
  timeout_sec        = 5
}
