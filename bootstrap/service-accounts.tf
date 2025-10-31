# Service account for Terraform/Terragrunt deployments
# This service account is used by CI/CD pipelines to deploy infrastructure

resource "google_service_account" "tf_deployer" {
  account_id   = "tf-deployer"
  display_name = "Terraform Deployer"
  description  = "Service account for Terraform/Terragrunt deployments"
  project      = var.project_id
}

# IAM bindings for the tf-deployer service account
# These permissions allow the service account to manage infrastructure

# Storage Admin - Required for managing Terraform state in GCS
resource "google_project_iam_member" "tf_deployer_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.tf_deployer.email}"
}

# Cloud Functions Admin - Required for deploying Cloud Functions
resource "google_project_iam_member" "tf_deployer_cloudfunctions_admin" {
  project = var.project_id
  role    = "roles/cloudfunctions.admin"
  member  = "serviceAccount:${google_service_account.tf_deployer.email}"
}

# Service Account User - Required to deploy resources that use service accounts
resource "google_project_iam_member" "tf_deployer_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.tf_deployer.email}"
}

# Service Usage Admin - Required to enable/manage GCP APIs
resource "google_project_iam_member" "tf_deployer_service_usage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${google_service_account.tf_deployer.email}"
}

# Service Account Admin - Required to manage service accounts for Cloud Functions
resource "google_project_iam_member" "tf_deployer_sa_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.tf_deployer.email}"
}

# Pub/Sub Admin - Required for managing Pub/Sub topics and subscriptions
resource "google_project_iam_member" "tf_deployer_pubsub_admin" {
  project = var.project_id
  role    = "roles/pubsub.admin"
  member  = "serviceAccount:${google_service_account.tf_deployer.email}"
}

# Project IAM Admin - Required to manage IAM policies on the project
resource "google_project_iam_member" "tf_deployer_project_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.tf_deployer.email}"
}
