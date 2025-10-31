terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Bootstrap uses local state since it creates the remote state bucket
  # After initial apply, you can optionally migrate to remote state
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "google" {
  project = var.project_id
}
