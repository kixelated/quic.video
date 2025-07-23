resource "google_compute_instance" "pub" {
  name = "pub-${local.pub.region}"

  machine_type = local.pub.machine
  zone         = local.pub.zone

  boot_disk {
    initialize_params {
      image = local.pub.image

      size = 50 # 50 GB
      type = "pd-standard"
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
      addr         = "relay.${var.domain}"
      docker_image = var.docker_hang
      region       = local.pub.region

      # A token used to publish demo/bbb.hang
      # cargo run --bin moq-token -- --key root.jwk sign --root "demo" --publish "" > demo-pub.jwt
      demo_token = trimspace(file("demo-pub.jwt"))
    })
  }

  service_account {
    scopes = ["cloud-platform"]
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
