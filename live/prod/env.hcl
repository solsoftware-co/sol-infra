# Production environment configuration

locals {
  environment = "prod"
  
  # Production-specific defaults
  min_instance_count = 0
  max_instance_count = 3
  available_memory   = "512M"
  lifecycle_days     = 30
  
  # Common prod project settings
  project_id_suffix = ""
}
