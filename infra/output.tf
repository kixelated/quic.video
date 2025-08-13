 output "relay_nameservers" {
    value = google_dns_managed_zone.relay.name_servers
    description = "Add these as NS records in Cloudflare for relay.moq.dev"
  }
