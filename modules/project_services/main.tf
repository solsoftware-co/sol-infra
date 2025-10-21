variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "services" {
  description = "List of GCP services to enable"
  type        = set(string)
  default = [
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "eventarc.googleapis.com",
    "pubsub.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
  ]
}

variable "disable_on_destroy" {
  description = "Whether to disable services when destroying"
  type        = bool
  default     = false
}

resource "google_project_service" "this" {
  for_each = var.services
  project  = var.project_id
  service  = each.value

  disable_on_destroy = var.disable_on_destroy
}

output "enabled_services" {
  description = "List of enabled services"
  value       = [for s in google_project_service.this : s.service]
}
