# GCS bucket for storing Terraform state
# This bucket is used by all Terragrunt configurations in the live/ directory

resource "google_storage_bucket" "tfstate" {
  name     = "${var.project_id}-tfstate"
  location = var.state_bucket_location
  project  = var.project_id

  # Prevent accidental deletion of state files
  force_destroy = false

  # Enable versioning to preserve state history
  versioning {
    enabled = true
  }

  # Lifecycle rules to manage old versions
  lifecycle_rule {
    condition {
      num_newer_versions = 10
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  # Uniform bucket-level access
  uniform_bucket_level_access {
    enabled = true
  }

  # Encryption
  encryption {
    default_kms_key_name = null # Uses Google-managed encryption by default
  }

  labels = {
    purpose     = "terraform-state"
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Grant the tf-deployer service account access to the state bucket
resource "google_storage_bucket_iam_member" "tfstate_admin" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tf_deployer.email}"
}
