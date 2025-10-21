# Test environment configuration

locals {
  environment = "test"
  
  # Test-specific defaults
  min_instance_count = 0
  max_instance_count = 1
  available_memory   = "256M"
  lifecycle_days     = 7
  
  # Common test project settings
  # Override these in each service's terragrunt.hcl if needed
  project_id_suffix = "-test"
}
