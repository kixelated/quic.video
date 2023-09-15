variable "project" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

output "project" {
  value       = var.project
  description = "GCloud Project ID"
}

output "region" {
  value       = var.region
  description = "GCloud Region"
}

output "zone" {
  value       = var.zone
  description = "GCloud Zone"
}

output "relay_image" {
  value       = "gcr.io/${var.project}/relay"
  description = "Relay docker image address"
}