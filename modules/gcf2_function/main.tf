variable "name" {
  description = "Cloud Function name"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the function runtime"
  type        = string
}

variable "topic_id" {
  description = "Pub/Sub topic ID for trigger"
  type        = string
}

variable "source_bucket" {
  description = "GCS bucket containing function source"
  type        = string
}

variable "source_object" {
  description = "GCS object name of function source zip"
  type        = string
}

variable "entry_point" {
  description = "Function entry point"
  type        = string
}

variable "runtime" {
  description = "Runtime for the function"
  type        = string
  default     = "nodejs22"
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

variable "ingress_settings" {
  description = "Ingress settings for the function"
  type        = string
  default     = "ALLOW_INTERNAL_ONLY"
}

variable "env_vars" {
  description = "Environment variables for the function"
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

variable "labels" {
  description = "Labels to apply to the function"
  type        = map(string)
  default     = {}
}

resource "google_cloudfunctions2_function" "this" {
  name        = var.name
  location    = var.region
  description = "Managed by Terraform"
  labels      = var.labels

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point
    source {
      storage_source {
        bucket = var.source_bucket
        object = var.source_object
      }
    }
    environment_variables = {
      GOOGLE_NODE_RUN_SCRIPTS = ""
    }
  }

  service_config {
    service_account_email          = var.service_account_email
    available_memory               = var.available_memory
    timeout_seconds                = var.timeout_seconds
    min_instance_count             = var.min_instance_count
    max_instance_count             = var.max_instance_count
    all_traffic_on_latest_revision = true
    ingress_settings               = var.ingress_settings
    environment_variables          = var.env_vars

    dynamic "secret_environment_variables" {
      for_each = var.secret_env_vars
      content {
        key        = secret_environment_variables.key
        project_id = var.project_id
        secret     = secret_environment_variables.value.secret
        version    = secret_environment_variables.value.version
      }
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = var.topic_id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}

output "name" {
  description = "Function name"
  value       = google_cloudfunctions2_function.this.name
}

output "uri" {
  description = "Function URI"
  value       = google_cloudfunctions2_function.this.service_config[0].uri
}

output "id" {
  description = "Function ID"
  value       = google_cloudfunctions2_function.this.id
}
