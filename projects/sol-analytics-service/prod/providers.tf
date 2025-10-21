terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "gcs" {
  #   bucket = "sol-terraform-state"
  #   prefix = "sol-analytics-service/prod"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
