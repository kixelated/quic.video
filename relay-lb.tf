# Global anycast UDP load balancer - ordered based on data flow

# Get a domain name for the anycast address.
resource "google_dns_record_set" "relay_lb" {
  name         = "relay.quic.video."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.root.name
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
  target                = google_compute_target_pool.relay_lb.self_link
  ip_address            = google_compute_global_address.relay_lb.address
}

# Register the list of possible instances to use
resource "google_compute_target_pool" "relay_lb" {
  name      = "relay-lb"
  instances = values(google_compute_instance.relay)[*].self_link

  health_checks = [
    google_compute_http_health_check.relay.name,
  ]
}
