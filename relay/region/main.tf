input "region" {
  value       = var.region
  description = "GCloud Region"
}

input "instances" {
  type        = number
  description = "Instance count"
}

input "image" {
  type = string

}

resource "google_compute_instance" "relay" {
  count = var.instances

  name         = "relay-${var.region}-${count.index}"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOT
    #! /bin/bash
    docker run --network="host" -d ${vars.relay_image}
  EOT

  service_account {
    scopes = ["cloud-platform"]
  }
}
