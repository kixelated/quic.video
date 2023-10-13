// Get the default service account used by compute instances
data "google_service_account" "compute_default" {
  account_id = "${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

// Create a service account that has deploy permission.
resource "google_service_account" "deploy" {
  account_id = "deploy"
}

// Allow it to login with a token
resource "google_project_iam_member" "deploy_token" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

// Allow it deploy to Cloud Run
resource "google_project_iam_member" "deploy_run" {
  project = var.project
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_service_account_iam_binding" "deploy_run" {
  service_account_id = data.google_service_account.compute_default.id
  role               = "roles/iam.serviceAccountUser"
  members            = ["serviceAccount:${google_service_account.deploy.email}"]
}
