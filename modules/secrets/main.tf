variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "secrets" {
  description = "Map of secret configurations"
  type = map(object({
    secret_data = string
    labels      = map(string)
  }))
  default = {}
}

variable "secret_accessors" {
  description = "Map of secret_id to list of service account emails that can access it"
  type        = map(list(string))
  default     = {}
}

resource "google_secret_manager_secret" "secrets" {
  for_each  = var.secrets
  project   = var.project_id
  secret_id = each.key

  labels = each.value.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "versions" {
  for_each    = var.secrets
  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value.secret_data
}

resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = {
    for pair in flatten([
      for secret_id, sa_emails in var.secret_accessors : [
        for sa in sa_emails : {
          key       = "${secret_id}|${sa}"
          secret_id = secret_id
          member    = "serviceAccount:${sa}"
        }
      ]
    ]) : pair.key => pair
  }

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.member

  depends_on = [google_secret_manager_secret.secrets]
}

output "secret_ids" {
  description = "Map of secret names to their IDs"
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.id }
}
