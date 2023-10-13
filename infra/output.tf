output "deploy_account" {
  value = google_service_account.deploy.email
}

output "api_url" {
  value = google_cloud_run_v2_service.api.uri
}
