output "deploy_account" {
  value = google_service_account.deploy.email
}

output "deploy_registry" {
  description = "The URL for the Artifact Registry Docker repository"
  value       = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.deploy.repository_id}"
}
