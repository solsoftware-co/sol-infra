variable "name" {
  description = "Topic name"
  type        = string
}

variable "labels" {
  description = "Labels to apply to the topic"
  type        = map(string)
  default     = {}
}

variable "publisher_sas" {
  description = "Service account emails allowed to publish to the topic"
  type        = set(string)
  default     = []
}

variable "message_retention_duration" {
  description = "Message retention duration (e.g., '604800s' for 7 days)"
  type        = string
  default     = "604800s"
}

resource "google_pubsub_topic" "this" {
  name   = var.name
  labels = var.labels

  message_retention_duration = var.message_retention_duration
}

resource "google_pubsub_topic_iam_member" "publisher" {
  for_each = var.publisher_sas
  topic    = google_pubsub_topic.this.name
  role     = "roles/pubsub.publisher"
  member   = "serviceAccount:${each.value}"
}

output "id" {
  description = "Topic ID"
  value       = google_pubsub_topic.this.id
}

output "name" {
  description = "Topic name"
  value       = google_pubsub_topic.this.name
}
