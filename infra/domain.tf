// Set up a DNS zone for our domain.
resource "google_dns_managed_zone" "relay" {
  name     = "relay"
  dns_name = "relay.${var.domain}."
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

  revoke_certificate_on_destroy = false

  dns_challenge {
    provider = "gcloud"
    config = {
      GCE_PROJECT = var.project
      GCE_ZONE_ID = google_dns_managed_zone.relay.name
    }
  }
}
