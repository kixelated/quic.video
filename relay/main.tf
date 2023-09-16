
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

  metadata = {
    # TODO recreate on change
    user-data = templatefile("${path.module}/init.yml.tpl", {
      image = var.image
      email = var.email
      crt   = var.crt
      key   = var.key
    })
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  # For the firewall
  tags = ["relay"]

  # There seems to be a terraform bug causing this to be recreated on every apply
  lifecycle {
    ignore_changes = [boot_disk]
  }
}

resource "google_compute_address" "relay" {
  count = var.instances

  name   = "relay-${var.region}-${count.index}"
  region = var.region
}

resource "google_dns_record_set" "relay" {
  count = var.instances

  name         = "${var.region}-${count.index}.${var.domain}."
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
