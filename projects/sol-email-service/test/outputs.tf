output "function_name" {
  description = "Cloud Function name"
  value       = module.function.name
}

output "function_uri" {
  description = "Cloud Function URI"
  value       = module.function.uri
}

output "topic_name" {
  description = "Pub/Sub topic name"
  value       = module.topic.name
}

output "topic_id" {
  description = "Pub/Sub topic ID"
  value       = module.topic.id
}

output "runtime_sa_email" {
  description = "Runtime service account email"
  value       = module.runtime_sa.email
}

output "source_bucket" {
  description = "Function source bucket name"
  value       = module.source_bucket.name
}
