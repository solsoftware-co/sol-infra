# Root Terragrunt configuration
# This file contains common configuration that applies to all environments

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  
  # Extract project and service from path
  # Path structure: live/{env}/{service}/terragrunt.hcl
  path_components = split("/", path_relative_to_include())
  service_name    = length(local.path_components) > 0 ? local.path_components[length(local.path_components) - 1] : ""
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
EOF
}

# Configure remote state
remote_state {
  backend = "gcs"
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  
  config = {
    bucket   = "${get_env("TF_VAR_project_id", "sol-infra")}-tfstate"
    prefix   = "${local.env}/${local.service_name}"
    project  = get_env("TF_VAR_project_id", "sol-infra")
    location = "us"
  }
}

# Common inputs that apply to all environments
inputs = {
  # These can be overridden by environment-specific configs
}
