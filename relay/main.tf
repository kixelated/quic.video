resource "google_compute_instance" "relay" {
  count = var.instances

  name         = "relay-${var.region}-${count.index}"
  machine_type = "t2a-standard-1"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-arm64-stable"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.relay[count.index].address
    }
  }

  metadata_startup_script = <<-EOT
    #! /bin/bash
    curl https://sdk.cloud.google.com | bash
    exec -l $SHELL
    gcloud init

    CRT="/etc/cert/relay.${var.domain}.crt"
    KEY="/etc/cert/relay.${var.domain}.key"

    gcloud secrets versions access latest --secret="relay-cert" --out-file "$CRT"
    gcloud secrets versions access latest --secret="relay-key" --out-file "$KEY"

    docker run -d --name moq-relay \
      --network="host" -p 443:443 \
      -e RUST_LOG=info \
      ${var.image}
      moq-relay --bind [::]:443 --cert "$CRT" --key "$KEY"
  EOT

  service_account {
    scopes = ["cloud-platform"]

    email = google_service_account.relay.email
  }

  # For the firewall
  tags = ["relay"]
}

resource "google_compute_address" "relay" {
  count = var.instances

  name   = "relay-${var.region}-${count.index}"
  region = var.region
}

resource "google_dns_record_set" "relay" {
  count = var.instances

  name         = "${var.region}-${count.index}.relay.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_zone
  rrdatas      = [google_compute_address.relay[count.index].address]
}

# Allow TCP 80 and UDP 443
resource "google_compute_firewall" "relay" {
  name    = "relay"
  network = "default"

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

# Allow the instance to access secrets
resource "google_service_account" "relay" {
  account_id = "relay-instance"
}

data "google_project" "current" {}

resource "google_project_iam_member" "relay_secrets" {
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.relay.email}"
  project = data.google_project.current.project_id
}
