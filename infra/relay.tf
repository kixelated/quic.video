resource "google_compute_instance" "relay" {
  for_each = local.relays

  name = "relay-${each.key}"

  // https://cloud.google.com/compute/docs/general-purpose-machines#t2a_machine_types
  // The relay uses virtually no CPU, so we can use a cheap ARM host.
  // We should increase the instance size until network is the bottleneck.
  // Then we scale out to more instances instead.
  machine_type = each.value.machine
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = each.value.image
      size  = 50 # 50 GB
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.relay[each.key].address
    }
  }

  metadata = {
    # cloud-init template
    user-data = templatefile("${path.module}/relay.yml.tpl", {
      docker_image = var.docker_relay

      # The external address and certs
      public_host = var.domain
      public_cert = "${acme_certificate.relay.certificate_pem}${acme_certificate.relay.issuer_pem}"
      public_key  = acme_certificate.relay.private_key_pem

      # Certs used for internal traffic
      internal_cert = "${tls_locally_signed_cert.relay_internal[each.key].cert_pem}${tls_self_signed_cert.internal.cert_pem}"
      internal_key  = tls_private_key.relay_internal[each.key].private_key_pem
      internal_ca   = tls_self_signed_cert.internal.cert_pem

      # The name we're using for clustering
      # We reuse the GCE provided DNS: VM_NAME.ZONE.c.PROJECT_ID.internal
      # See: https://cloud.google.com/compute/docs/internal-dns
      cluster_node = "relay-${each.key}.${each.value.zone}.c.${var.project}.internal"
      cluster_root = "${local.root}.c.${var.project}.internal"

      # The root key and token, used to authenticate nodes
      # cargo run --bin moq-token -- --key root.jwk generate > root.jwk
      root_key      = trimspace(file("root.jwk"))

      # cargo run --bin moq-token -- --key root.jwk sign --publish "" --subscribe "" --cluster > cluster.jwt
      cluster_token = trimspace(file("cluster.jwt"))
    })
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  # For the firewall
  tags = ["relay"]

  lifecycle {
    # There seems to be a terraform bug causing this to be recreated on every apply
    ignore_changes = [boot_disk]
  }

  allow_stopping_for_update = true
}

resource "google_compute_address" "relay" {
  for_each = local.relays

  name   = "relay-${each.key}"
  region = each.value.region
}

# Create a DNS entry for each node.
resource "google_dns_record_set" "relay" {
  for_each = local.relays

  name         = "${each.key}.relay.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  rrdatas      = [google_compute_address.relay[each.key].address]
}

# Allow UDP 443
resource "google_compute_firewall" "relay" {
  name    = "relay"
  network = "default"

  allow {
    protocol = "udp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["relay"]
}

# We must use a legacy health check for the UDP load balancer
resource "google_compute_http_health_check" "relay" {
  name               = "relay"
  request_path       = "/health"
  check_interval_sec = 5
  timeout_sec        = 5
}

# Create an internal TLS certificate for the relay
resource "tls_private_key" "relay_internal" {
  for_each = local.relays

  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "relay_internal" {
  for_each        = local.relays
  private_key_pem = tls_private_key.relay_internal[each.key].private_key_pem

  subject {
    common_name = "relay-${each.key}"
  }

  # Valid for the default Google DNS entry
  dns_names = ["relay-${each.key}.${each.value.zone}.c.${var.project}.internal"]
}

resource "tls_locally_signed_cert" "relay_internal" {
  for_each = local.relays

  cert_request_pem   = tls_cert_request.relay_internal[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.internal.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.internal.cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}
