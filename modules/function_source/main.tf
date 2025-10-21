variable "bucket_name" {
  description = "GCS bucket name for function source"
  type        = string
}

variable "object_name" {
  description = "GCS object name for the zip file"
  type        = string
}

variable "source_path" {
  description = "Local path to the function source zip"
  type        = string
}

resource "google_storage_bucket_object" "source" {
  name         = var.object_name
  bucket       = var.bucket_name
  source       = var.source_path
  content_type = "application/zip"
}

output "bucket" {
  description = "Source bucket name"
  value       = var.bucket_name
}

output "object" {
  description = "Source object name"
  value       = google_storage_bucket_object.source.name
}

output "generation" {
  description = "Object generation (version)"
  value       = google_storage_bucket_object.source.generation
}
