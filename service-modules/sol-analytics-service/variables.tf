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
  default     = "sol-analytics-service"
}

variable "publisher_sas" {
  description = "Service account emails allowed to publish to the topic"
  type        = set(string)
  default     = []
}

variable "artifact_reader_sas" {
  description = "Service account emails allowed to read from the artifacts bucket"
  type        = set(string)
  default     = []
}

variable "env_vars" {
  description = "Additional environment variables for the function"
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Secret environment variables for the function"
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}
}

variable "secret_bindings" {
  description = "Secret Manager IAM bindings"
  type = list(object({
    project_id = string
    secret_id  = string
    role       = string
    members    = set(string)
  }))
  default = []
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
  default     = 540
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
