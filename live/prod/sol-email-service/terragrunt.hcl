# Terragrunt configuration for sol-email-service PROD environment
# This file only contains environment-specific overrides

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Include environment configuration
include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

# Point to the service module (DRY!)
terraform {
  source = "../../../service-modules/sol-email-service"
}

# Environment-specific inputs
inputs = {
  environment = include.env.locals.environment
  
  # Project configuration
  project_id     = "sol-infra"
  project_number = "518590126607"
  region         = "us-central1"
  
  # Function configuration - uses env defaults
  available_memory      = include.env.locals.available_memory
  min_instance_count    = include.env.locals.min_instance_count
  max_instance_count    = include.env.locals.max_instance_count
  lifecycle_days_delete = include.env.locals.lifecycle_days
  timeout_seconds       = 60
  
  # Function source
  source_zip_path = "${get_terragrunt_dir()}/../../../function-source.zip"
  
  # Service accounts and IAM
  publisher_sas = []
  
  # Environment variables
  env_vars = {
    DEBUG     = "false"
    LOG_LEVEL = "info"
  }
  
  # Secrets (use environment variables or secret management)
  # mailgun_api_key = get_env("MAILGUN_API_KEY", "")
}
