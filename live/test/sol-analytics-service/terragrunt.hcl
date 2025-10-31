# Terragrunt configuration for sol-analytics-service TEST environment
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
# Use source map to include both service-modules and modules directories
terraform {
  source = "${get_repo_root()}//service-modules/sol-analytics-service"
}

# Environment-specific inputs
inputs = {
  environment = include.env.locals.environment
  
  # Project configuration
  project_id     = "sol-infra-test"
  project_number = "518590126607"
  region         = "us-central1"
  
  # Function configuration - uses env defaults
  available_memory      = include.env.locals.available_memory
  min_instance_count    = include.env.locals.min_instance_count
  max_instance_count    = include.env.locals.max_instance_count
  lifecycle_days_delete = include.env.locals.lifecycle_days
  timeout_seconds       = 540
  
  # Function source
  source_zip_path = "${get_terragrunt_dir()}/../../../function-source.zip"
  
  # Service accounts and IAM
  publisher_sas       = []
  artifact_reader_sas = []
  
  # Environment variables
  env_vars = {
    DEBUG     = "true"
    LOG_LEVEL = "debug"
  }
  
  # Secrets and IAM
  secret_env_vars = {}
  secret_bindings = []
}
