resource "google_compute_network" "relay" {
  name                    = "relay"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "relay" {
  for_each = local.relays

  name             = "relay-${each.key}"
  ip_cidr_range    = "10.${index(keys(local.relays), each.key) + 1}.0.0/24"
  region           = each.value.region
  network          = google_compute_network.relay.id
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}

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
    network    = google_compute_network.relay.id
    subnetwork = google_compute_subnetwork.relay[each.key].id
    stack_type = "IPV4_IPV6"

    access_config {
      nat_ip                 = google_compute_address.relay[each.key].address
      network_tier           = "PREMIUM"
      public_ptr_domain_name = "relay.${each.key}.${var.domain}."
    }

    ipv6_access_config {
      network_tier           = "PREMIUM"
      public_ptr_domain_name = "relay.${each.key}.${var.domain}."
      external_ipv6          = google_compute_address.relay_ipv6[each.key].address
    }
  }

  metadata = {
    # cloud-init template
    user-data = templatefile("${path.module}/relay.yml.tpl", {
      docker = var.docker

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
    })
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  # For the firewall
  tags = ["relay"]

  allow_stopping_for_update = true
}

resource "google_compute_address" "relay" {
  for_each = local.relays

  name   = "relay-${each.key}"
  region = each.value.region

  address_type = "EXTERNAL"
  ip_version   = "IPV4"
  network_tier = "PREMIUM"
}

resource "google_compute_address" "relay_ipv6" {
  for_each = local.relays

  name               = "relay-${each.key}-ipv6"
  region             = each.value.region
  address_type       = "EXTERNAL"
  ip_version         = "IPV6"
  ipv6_endpoint_type = "VM"
  network_tier       = "PREMIUM"
  subnetwork         = google_compute_subnetwork.relay[each.key].id
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
  network = google_compute_network.relay.id

  allow {
    protocol = "udp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["relay"]
}

# Allow UDP 443 for IPv6
resource "google_compute_firewall" "relay_ipv6" {
  name    = "relay-ipv6"
  network = google_compute_network.relay.id

  allow {
    protocol = "udp"
    ports    = ["443"]
  }

  source_ranges = ["::/0"]
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
