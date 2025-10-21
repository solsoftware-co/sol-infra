variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "sol-infra"
}

variable "project_number" {
  description = "GCP project number"
  type        = string
  default     = "518590126607"
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
  default     = "../../../function-source.zip"
}

variable "source_object_name" {
  description = "Name of the source object in GCS"
  type        = string
  default     = "function-source.zip"
}
