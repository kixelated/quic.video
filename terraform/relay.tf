resource "google_compute_address" "relay" {
  name = "relay"
}

resource "google_compute_instance" "relay" {
  name         = "relay"
  machine_type = "n1-standard-1"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.relay.address
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Add your startup script or installation commands here
    EOT
}

output "relay_ip" {
  value = google_compute_address.relay.address
}
