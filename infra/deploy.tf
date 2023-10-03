// Registry available to Github Actions
resource "google_artifact_registry_repository" "deploy" {
  location      = var.region
  repository_id = "deploy"
  format        = "DOCKER"
}

// Create a service account that has deploy permission.
resource "google_service_account" "deploy" {
  account_id = "deploy"
}

resource "google_project_iam_member" "deploy_artifact" {
  project = var.project
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_project_iam_member" "deploy_token" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_project_iam_member" "deploy_run" {
  project = var.project
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.deploy.email}"
}
