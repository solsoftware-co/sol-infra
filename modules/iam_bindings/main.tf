variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region (required for Cloud Run IAM)"
  type        = string
  default     = "us-central1"
}

variable "project_roles" {
  description = "Map of role to list of members for project-level IAM"
  type        = map(list(string))
  default     = {}
}

variable "sa_act_as" {
  description = "Map of service account email to list of members who can actAs"
  type        = map(list(string))
  default     = {}
}

variable "secret_bindings" {
  description = "List of secret IAM bindings"
  type = list(object({
    project_id = string
    secret_id  = string
    role       = string
    members    = set(string)
  }))
  default = []
}

variable "run_invokers" {
  description = "List of Cloud Run service invoker bindings"
  type = list(object({
    service = string
    role    = string
    members = set(string)
  }))
  default = []
}

# Project-level IAM bindings
resource "google_project_iam_member" "project_roles" {
  for_each = {
    for pair in flatten([
      for role, members in var.project_roles : [
        for m in members : {
          key    = "${role}|${m}"
          role   = role
          member = m
        }
      ]
    ]) : pair.key => pair
  }

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}

# Service Account actAs permissions
resource "google_service_account_iam_member" "sa_act_as" {
  for_each = {
    for pair in flatten([
      for sa_email, members in var.sa_act_as : [
        for m in members : {
          key     = "${sa_email}|${m}"
          sa_name = "projects/${var.project_id}/serviceAccounts/${sa_email}"
          member  = m
        }
      ]
    ]) : pair.key => pair
  }

  service_account_id = each.value.sa_name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value.member
}

# Secret Manager IAM bindings
resource "google_secret_manager_secret_iam_member" "secret_bindings" {
  for_each = {
    for pair in flatten([
      for s in var.secret_bindings : [
        for m in s.members : {
          key        = "${s.project_id}|${s.secret_id}|${s.role}|${m}"
          project_id = s.project_id
          secret_id  = s.secret_id
          role       = s.role
          member     = m
        }
      ]
    ]) : pair.key => pair
  }

  project   = each.value.project_id
  secret_id = each.value.secret_id
  role      = each.value.role
  member    = each.value.member
}

# Cloud Run service invoker permissions
resource "google_cloud_run_service_iam_member" "run_invokers" {
  for_each = {
    for pair in flatten([
      for r in var.run_invokers : [
        for m in r.members : {
          key     = "${r.service}|${r.role}|${m}"
          service = r.service
          role    = r.role
          member  = m
        }
      ]
    ]) : pair.key => pair
  }

  location = var.region
  service  = each.value.service
  role     = each.value.role
  member   = each.value.member
}
