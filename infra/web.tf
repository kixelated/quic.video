resource "google_cloud_run_v2_service" "web" {
  name     = "web"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.deploy.repository_id}/moq-js:latest"
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  service     = google_cloud_run_v2_service.web.name
  location    = google_cloud_run_v2_service.web.location
  project     = google_cloud_run_v2_service.web.project
  policy_data = data.google_iam_policy.noauth.policy_data
}

module "web_lb" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 9.0"

  project = var.project
  name    = "web"

  ssl                             = true
  managed_ssl_certificate_domains = [var.domain]
  https_redirect                  = true
  backends = {
    default = {
      protocol                = "HTTP"
      enable_cdn              = false
      custom_response_headers = ["Cross-Origin-Opener-Policy: same-origin", "Cross-Origin-Embedder-Policy: require-corp"]

      groups = [
        {
          group = google_compute_region_network_endpoint_group.web.id
        }
      ]

      iap_config = {
        enable = false
      }

      log_config = {
        enable = false
      }
    }
  }
}



resource "google_compute_region_network_endpoint_group" "web" {
  name                  = "web"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.web.name
  }
}

// Create a DNS record that points to the web load balancer.
resource "google_dns_record_set" "web" {
  managed_zone = google_dns_managed_zone.public.name
  name         = "${var.domain}."
  type         = "A"
  ttl          = 600

  rrdatas = [module.web_lb.external_ip]
}
