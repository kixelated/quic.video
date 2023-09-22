# Geo DNS
resource "google_dns_record_set" "relay_global" {
  name         = "relay.${var.domain}."
  type         = "A"
  ttl          = 60
  managed_zone = google_dns_managed_zone.public.name

  routing_policy {
    dynamic "geo" {
      for_each = local.regions

      content {
        location = geo.value.region
        rrdatas = [
          for idx in range(geo.value.count) :
          google_compute_address.relay["${geo.key}-${idx}"].address
        ]
      }
    }
  }
}

# Regional DNS if that's not working
resource "google_dns_record_set" "relay_region" {
  for_each = local.regions

  name         = "${each.key}.relay.${var.domain}."
  type         = "A"
  ttl          = 60
  managed_zone = google_dns_managed_zone.public.name
  rrdatas = [
    for idx in range(each.value.count) :
    google_compute_address.relay["${each.key}-${idx}"].address
  ]
}

# Unfortunately GCP doesn't support global UDP load balancing despite their marketing.
# oof there goes a few hours; here's my progress for posterity:

/*
# Get a domain name for the anycast address.
resource "google_dns_record_set" "relay_lb" {
  name         = "relay.quic.video."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  rrdatas      = [google_compute_global_forwarding_rule.relay_lb.ip_address]
}

# Get an anycast address.
resource "google_compute_global_address" "relay_lb" {
  name         = "relay-lb"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

# Set up a global forwarding rule
resource "google_compute_global_forwarding_rule" "relay_lb" {
  name                  = "relay-lb"
  ip_protocol           = "UDP"
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  target                = data.google_compute_backend_service.relay_lb.self_link
  ip_address            = google_compute_global_address.relay_lb.address
}

# Register the list of possible instances to use
resource "google_compute_backend_service" "relay_lb" {
  name                  = "relay-lb"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "UDP" # This is the problem; it's not supported
  port_name             = "quic"

  dynamic "backend" {
    for_each = local.regions

    content {
      group          = google_compute_instance_group.relay_lb[backend.key].self_link
      balancing_mode = "CONNECTION" # apparently required?
    }
  }

  health_checks = [
    google_compute_http_health_check.relay.self_link
  ]
}
*/
