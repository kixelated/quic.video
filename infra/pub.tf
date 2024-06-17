resource "google_compute_instance" "pub" {
  name = "pub-${local.pub.region}"

  machine_type = local.pub.machine
  zone         = local.pub.zone

  boot_disk {
    initialize_params {
      image = local.pub.image
    }
  }

  network_interface {
    network = "default"

    # Give the instance a public IP address so it can download from the internet.
    # If we add more instances, it's probably cheaper to set up a NAT instead.
    access_config {
      nat_ip       = google_compute_address.pub.address
      network_tier = "STANDARD"
    }
  }

  metadata = {
    # cloud-init template
    user-data = templatefile("${path.module}/pub.yml.tpl", {
      addr   = "relay.${var.domain}"
      image  = var.image_pub
      region = local.pub.region
    })
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  lifecycle {
    # There seems to be a terraform bug causing this to be recreated on every apply
    # ignore_changes = [boot_disk]
  }

  allow_stopping_for_update = true
}

# Create an IP address just so we can access the internet without a NAT.
resource "google_compute_address" "pub" {
  name         = "pub-${local.pub.region}"
  region       = local.pub.region
  address_type = "EXTERNAL"
  network_tier = "STANDARD"
}
