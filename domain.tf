variable "domain" {
  description = "domain"
}

// Set up a DNS zone for our domain.
resource "google_dns_managed_zone" "root" {
  name     = "root"
  dns_name = "${var.domain}."
}

// Create a certificate for the domain.
resource "google_compute_managed_ssl_certificate" "root" {
  name        = "root"
  description = "Cert for ${var.domain}."

  managed {
    domains = ["${var.domain}."]
  }

  lifecycle {
    create_before_destroy = true
  }
}
