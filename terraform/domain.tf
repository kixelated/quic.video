// Set up a DNS zone for our domain.
resource "google_dns_managed_zone" "dnszone" {
  name        = "quic-video-zone"
  dns_name    = "quic.video."
  description = "DNS zone for quic.video."
}

// The domain is manually purchased, so we run this command to point it to our DNS zone.
resource "null_resource" "dnsconfigure" {
  provisioner "local-exec" {
    command = <<-EOT
        gcloud beta domains registrations configure dns quic.video --cloud-dns-zone=quic-video-zone
        EOT
  }

  depends_on = [
    google_project_service.all,
    google_dns_managed_zone.dnszone
  ]
}

// Create a certificate for the domain.
resource "google_compute_managed_ssl_certificate" "cert" {
  name        = "quic-video-cert"
  description = "Cert for quic.video."

  managed {
    domains = ["quic.video."]
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Create a DNS record that points to the load balancer.
resource "google_dns_record_set" "a" {
  name         = "quic.video."
  managed_zone = google_dns_managed_zone.dnszone.name
  type         = "A"
  ttl          = 60

  rrdatas    = [google_compute_global_address.ip.address]
  depends_on = [google_compute_global_address.ip]
}
