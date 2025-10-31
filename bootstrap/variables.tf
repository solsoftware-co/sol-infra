variable "project_id" {
  description = "The GCP project ID where bootstrap resources will be created"
  type        = string
}

variable "project_number" {
  description = "The GCP project number (required for Cloud Build service account)"
  type        = string
}

variable "environment" {
  description = "Environment name (test, prod, etc.)"
  type        = string
}

variable "state_bucket_location" {
  description = "Location for the Terraform state bucket"
  type        = string
  default     = "us"
}
