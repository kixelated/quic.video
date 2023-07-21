// Create a bucket to hold the static website.
resource "google_storage_bucket" "http_bucket" {
  name          = "quic-video-web"
  location      = "us-west1"
  force_destroy = true

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin          = ["quic.video"]
    method          = ["GET"]
    max_age_seconds = 3600
  }
}

// Create an IP address for the load balancer.
resource "google_compute_global_address" "ip" {
  name       = "quic-video-ip"
  ip_version = "IPV4"
}

resource "google_storage_bucket_iam_binding" "policy" {
  bucket = google_storage_bucket.http_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers",
  ]
  depends_on = [google_storage_bucket.http_bucket]
}

resource "google_compute_backend_bucket" "be" {
  name        = "quic-video-be"
  bucket_name = google_storage_bucket.http_bucket.name
  depends_on  = [google_storage_bucket.http_bucket]
}

resource "google_compute_url_map" "lb" {
  name            = "quic-video-lb"
  depends_on      = [google_compute_backend_bucket.be]
  default_service = google_compute_backend_bucket.be.id

  header_action {
    response_headers_to_add {
      header_name  = "Cross-Origin-Opener-Policy"
      header_value = "same-origin"
      replace      = false
    }

    response_headers_to_add {
      header_name  = "Cross-Origin-Embedder-Policy"
      header_value = "require-corp"
      replace      = false
    }
  }
}

resource "google_compute_target_https_proxy" "ssl-lb-proxy" {
  project          = "quic-video"
  name             = "quic-video-ssl-lb-proxy"
  url_map          = google_compute_url_map.lb.id
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.id]
  depends_on       = [google_compute_url_map.lb, google_compute_managed_ssl_certificate.cert]
}

resource "google_compute_global_forwarding_rule" "https-lb-forwarding-rule" {
  name                  = "quic-video-https-lb-forwarding-rule"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.ssl-lb-proxy.id
  ip_address            = google_compute_global_address.ip.id
  depends_on            = [google_compute_target_https_proxy.ssl-lb-proxy]
}

resource "google_compute_url_map" "http-redirect" {
  name = "http-redirect"

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT" // 301 redirect
    strip_query            = false
    https_redirect         = true // Redirect to HTTPS
  }
}

resource "google_compute_target_http_proxy" "http-redirect" {
  name    = "http-redirect"
  url_map = google_compute_url_map.http-redirect.self_link
}

resource "google_compute_global_forwarding_rule" "http-redirect" {
  name       = "quic-video-http-redirect"
  target     = google_compute_target_http_proxy.http-redirect.self_link
  ip_address = google_compute_global_address.ip.id
  port_range = "80"
}
