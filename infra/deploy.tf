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

// Allow assuming the cloud run service account
data "google_service_account" "compute_default" {
  account_id = "${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_service_account_iam_binding" "deploy_run" {
  service_account_id = data.google_service_account.compute_default.id
  role               = "roles/iam.serviceAccountUser"
  members            = ["serviceAccount:${google_service_account.deploy.email}"]
}
