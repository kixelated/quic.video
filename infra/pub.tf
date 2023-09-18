resource "google_compute_instance" "pub" {
  name         = "pub"
  machine_type = "t2a-standard-1"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-arm64-stable"
    }
  }

  network_interface {
    network = "default"
  }

  metadata = {
    # cloud-init template
    user-data = templatefile("${path.module}/pub.yml.tpl", {
      addr  = "relay.${var.domain}"
      image = var.image
    })
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  lifecycle {
    # There seems to be a terraform bug causing this to be recreated on every apply
    #ignore_changes = [boot_disk]
  }

  allow_stopping_for_update = true
}
