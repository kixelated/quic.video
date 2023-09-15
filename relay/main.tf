resource "google_compute_instance" "relay" {
  count = var.instances

  name         = "relay-${var.region}-${count.index}"
  machine_type = "n1-standard-1"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
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
    docker run -it --rm --name certbot \
      -v "/etc/letsencrypt:/etc/letsencrypt" \
      -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
      -p 80:80 \
      certbot/certbot certonly --standalone \
      -d ${google_dns_record_set.relay[count.index].name}

    docker run -d --network="host" -p 443:443 ${var.image} \
      -v "/etc/letsencrypt/live/${google_dns_record_set.relay[count.index].name}:/etc/cert" \
      moq-relay --bind [::]:443 --cert /etc/cert/fullchain.pem --key /etc/cert/privkey.pem
  EOT

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_address" "relay" {
  count = var.instances

  name   = "relay-${var.region}-${count.index}"
  region = var.region
}

resource "google_dns_record_set" "relay" {
  count = var.instances

  name         = "${count.index}.${var.region}.relay.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_zone
  rrdatas      = [google_compute_address.relay[count.index].address]
}
