// Set up a DNS zone for our domain.
resource "google_dns_managed_zone" "public" {
  name     = "public"
  dns_name = "${var.domain}."
}

// Create a managed certificate for the domain.
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

// We also need an unmanaged certificate for the relay, since there's no QUIC LBs available yet.
provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "relay" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "acme_registration" "relay" {
  account_key_pem = tls_private_key.relay.private_key_pem
  email_address   = var.email
}

resource "acme_certificate" "relay" {
  account_key_pem           = acme_registration.relay.account_key_pem
  common_name               = "relay.${var.domain}"
  subject_alternative_names = ["*.relay.${var.domain}"]
  key_type                  = tls_private_key.relay.ecdsa_curve

  dns_challenge {
    provider = "gcloud"

    config = {
      GCE_PROJECT = var.project
    }
  }
}
