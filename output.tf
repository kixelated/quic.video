output "relay_image" {
  value       = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.relay.name}/server"
  description = "Relay docker image address"
}
