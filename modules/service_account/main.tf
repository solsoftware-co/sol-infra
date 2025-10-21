variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "account_id" {
  description = "Service account ID"
  type        = string
}

variable "display_name" {
  description = "Service account display name"
  type        = string
}

variable "deployer_sa_email" {
  description = "Deployer service account email (granted actAs permission)"
  type        = string
  default     = ""
}

resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = var.account_id
  display_name = var.display_name
}

resource "google_service_account_iam_member" "act_as" {
  count              = var.deployer_sa_email != "" ? 1 : 0
  service_account_id = google_service_account.this.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.deployer_sa_email}"
}

output "email" {
  description = "Service account email"
  value       = google_service_account.this.email
}

output "id" {
  description = "Service account ID"
  value       = google_service_account.this.id
}

output "name" {
  description = "Service account name"
  value       = google_service_account.this.name
}
