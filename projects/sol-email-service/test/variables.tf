variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "sol-infra-test"
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
  default     = "../../../function-source.zip"
}

variable "source_object_name" {
  description = "Name of the source object in GCS"
  type        = string
  default     = "function-source.zip"
}
