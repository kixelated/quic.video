# Run a HTTP API on Cloud Run.
resource "google_cloud_run_v2_service" "api" {
  name     = "api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    containers {
      image   = "docker.io/kixelated/moq-rs"
      command = ["moq-api"]
      args    = ["--listen", "0.0.0.0:8080", "--redis", "redis://${google_redis_instance.api.host}:${google_redis_instance.api.port}"]

      ports {
        container_port = 8080
      }

      env {
        name  = "RUST_LOG"
        value = "info"
      }

      env {
        name  = "RUST_BACKTRACE"
        value = "1"
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.default.id
      egress    = "ALL_TRAFFIC"
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# Host a redis instance to keep state.
resource "google_redis_instance" "api" {
  name           = "api"
  memory_size_gb = 1
  region         = var.region

  authorized_network = "default"
}

# Allow everything on the VPC to access each other.
resource "google_vpc_access_connector" "default" {
  name           = "default"
  region         = var.region
  network        = "default"
  min_instances  = 2
  max_instances  = 4
  max_throughput = 400 # required or else it keeps recreating

  ip_cidr_range = "10.8.0.0/28"
}

// Make it public
resource "google_cloud_run_service_iam_policy" "api" {
  service     = google_cloud_run_v2_service.api.name
  location    = google_cloud_run_v2_service.api.location
  project     = google_cloud_run_v2_service.api.project
  policy_data = data.google_iam_policy.noauth.policy_data
}
