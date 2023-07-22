# VPC
/*
resource "google_compute_network" "relay" {
  name                    = "relay"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "relay" {
  name          = "relay"
  network       = google_compute_network.relay.name
  ip_cidr_range = "10.10.0.0/24"
}

# GKE cluster
resource "google_container_cluster" "relay" {
  name = "relay"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.relay.name
  subnetwork = google_compute_subnetwork.relay.name
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = google_container_cluster.relay.name
  cluster    = google_container_cluster.relay.name
  node_count = 1

  # Only run in a single zone for a single instance
  node_locations = [var.zone]

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    machine_type = "n1-standard-1"
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

output "relay_cluster_name" {
  value       = google_container_cluster.relay.name
  description = "GKE Cluster Name"
}

output "relay_cluster_host" {
  value       = google_container_cluster.relay.endpoint
  description = "GKE Cluster Host"
}
*/