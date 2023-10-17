// Create an interal DNS zone and use self-signed certificates
// This way we can ensure that instances talk to each other within network and over TLS
// It's not recommended to use terraform for this, but who cares.

/*
data "google_compute_network" "default" {
  name = "default"
}

// Create a DNS zone for private IPs
resource "google_dns_managed_zone" "internal" {
  name       = "internal"
  dns_name   = "internal.${var.domain}."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.default.self_link
    }
  }
}
*/

resource "tls_private_key" "internal" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "internal" {
  private_key_pem = tls_private_key.internal.private_key_pem

  subject {
    common_name = "${var.project}.internal"
  }

  validity_period_hours = 8760 # 1 year

  is_ca_certificate = true

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}
