variable "name" {
  description = "Bucket name"
  type        = string
}

variable "location" {
  description = "Bucket location"
  type        = string
  default     = "US"
}

variable "force_destroy" {
  description = "Allow bucket deletion with objects inside"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to the bucket"
  type        = map(string)
  default     = {}
}

variable "lifecycle_days_delete" {
  description = "Number of days after which objects will be deleted. Set to 0 to disable."
  type        = number
  default     = 0
}

variable "iam_writers" {
  description = "Service account emails allowed to write to the bucket"
  type        = set(string)
  default     = []
}

variable "iam_readers" {
  description = "Service account emails allowed to read from the bucket"
  type        = set(string)
  default     = []
}

variable "iam_deleters" {
  description = "Service account emails allowed to delete from the bucket"
  type        = set(string)
  default     = []
}

resource "google_storage_bucket" "this" {
  name                        = var.name
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
  labels                      = var.labels

  lifecycle {
    create_before_destroy = true
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_days_delete > 0 ? [1] : []
    content {
      action {
        type = "Delete"
      }
      condition {
        age = var.lifecycle_days_delete
      }
    }
  }
}

resource "google_storage_bucket_iam_member" "writers" {
  for_each = var.iam_writers
  bucket   = google_storage_bucket.this.name
  role     = "roles/storage.objectCreator"
  member   = "serviceAccount:${each.value}"
}

resource "google_storage_bucket_iam_member" "readers" {
  for_each = var.iam_readers
  bucket   = google_storage_bucket.this.name
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${each.value}"
}

resource "google_storage_bucket_iam_member" "deleters" {
  for_each = var.iam_deleters
  bucket   = google_storage_bucket.this.name
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${each.value}"
}

output "name" {
  description = "Bucket name"
  value       = google_storage_bucket.this.name
}

output "url" {
  description = "Bucket URL"
  value       = google_storage_bucket.this.url
}
