variable "environment" {
  description = "Environment name (test, prod, etc.)"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_number" {
  description = "GCP project number"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "function_name" {
  description = "Cloud Function name"
  type        = string
  default     = "sol-email-service"
}

variable "publisher_sas" {
  description = "Service account emails allowed to publish to the topic"
  type        = set(string)
  default     = []
}

variable "env_vars" {
  description = "Additional environment variables for the function"
  type        = map(string)
  default     = {}
}

variable "mailgun_api_key" {
  description = "Mailgun API key (secret). Leave empty to skip secret creation."
  type        = string
  default     = ""
  sensitive   = true
}

variable "source_zip_path" {
  description = "Local path to the function source zip file"
  type        = string
}

variable "source_object_name" {
  description = "Name of the source object in GCS"
  type        = string
  default     = "function-source.zip"
}

variable "available_memory" {
  description = "Memory available to the function"
  type        = string
  default     = "512M"
}

variable "timeout_seconds" {
  description = "Function timeout in seconds"
  type        = number
  default     = 60
}

variable "min_instance_count" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
}

variable "lifecycle_days_delete" {
  description = "Number of days after which objects will be deleted"
  type        = number
  default     = 30
}
