output "tf_deployer_email" {
  description = "Email address of the Terraform deployer service account"
  value       = google_service_account.tf_deployer.email
}

output "tf_deployer_unique_id" {
  description = "Unique ID of the Terraform deployer service account"
  value       = google_service_account.tf_deployer.unique_id
}

output "tfstate_bucket_name" {
  description = "Name of the Terraform state bucket"
  value       = google_storage_bucket.tfstate.name
}

output "tfstate_bucket_url" {
  description = "URL of the Terraform state bucket"
  value       = google_storage_bucket.tfstate.url
}
