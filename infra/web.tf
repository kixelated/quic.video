# Host a mostly-static website on Cloud Run.
resource "google_cloud_run_v2_service" "web" {
  name     = "web"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    containers {
      image = "docker.io/kixelated/moq-js"
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# Create a HTTPS load balancer that points to the web service.
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

      enable_cdn = true
      cdn_policy = {
        cache_mode = "USE_ORIGIN_HEADERS"
        cache_key_policy = {
          include_query_string = false
        }

        # Allow serving stale content up to a minute old while revalidating with origin.
        # The next page refresh will likely be served from the new cache.
        serve_while_stale = 60
      }
    }
  }
}

# Create a network endpoint group that points to the web service.
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

// Make it public
resource "google_cloud_run_service_iam_policy" "web" {
  service     = google_cloud_run_v2_service.web.name
  location    = google_cloud_run_v2_service.web.location
  project     = google_cloud_run_v2_service.web.project
  policy_data = data.google_iam_policy.noauth.policy_data
}
