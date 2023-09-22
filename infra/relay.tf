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
      image = var.image
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

  allow_stopping_for_update = true
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
  managed_zone = google_dns_managed_zone.public.name
  rrdatas      = [google_compute_address.relay[each.key].address]
}

# Allow UDP 443
resource "google_compute_firewall" "relay" {
  name    = "relay"
  network = "default"

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

/*
resource "google_dns_record_set" "relay-internal" {
  for_each = local.regions_flat

  name         = "${each.key}.internal.relay.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.private.name
  rrdatas      = [google_compute_instance.relay[each.key].network_interface[0].network_ip]
}

*/
