# Sol Email Service Infrastructure
# This module is shared across all environments

locals {
  deployer_sa_email = "tf-deployer@${var.project_id}.iam.gserviceaccount.com"
  topic_name        = "${var.function_name}-topic"
  
  # Service accounts
  cloud_build_sa     = "${var.project_number}@cloudbuild.gserviceaccount.com"
  compute_default_sa = "${var.project_number}-compute@developer.gserviceaccount.com"
  
  # Labels
  labels = {
    app        = var.function_name
    env        = var.environment
    managed_by = "terraform"
  }
}

# Enable required GCP services
module "services" {
  source     = "../../modules/project_services"
  project_id = var.project_id
  services = [
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "eventarc.googleapis.com",
    "pubsub.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
  ]
}

# Runtime service account
module "runtime_sa" {
  source            = "../../modules/service_account"
  project_id        = var.project_id
  account_id        = var.environment == "prod" ? "${var.function_name}-sa" : "${var.function_name}-sa-${var.environment}"
  display_name      = "SA for ${var.function_name} (${var.environment})"
  deployer_sa_email = local.deployer_sa_email
  
  depends_on = [module.services]
}

# Pub/Sub topic for email events
module "topic" {
  source        = "../../modules/pubsub_topic"
  name          = local.topic_name
  labels        = local.labels
  publisher_sas = var.publisher_sas
  
  depends_on = [module.services]
}

# Source bucket for function code
module "source_bucket" {
  source                = "../../modules/gcs_bucket"
  name                  = "${var.project_id}-${var.function_name}-gcf-src${var.environment == "prod" ? "" : "-${var.environment}"}"
  location              = upper(var.region) == "US" || upper(var.region) == "EU" ? upper(var.region) : "US"
  force_destroy         = true
  labels                = local.labels
  lifecycle_days_delete = var.lifecycle_days_delete
  
  depends_on = [module.services]
}

# IAM bindings (static only - no runtime SA references)
module "iam" {
  source     = "../../modules/iam_bindings"
  project_id = var.project_id
  region     = var.region

  project_roles = {
    "roles/run.admin"               = ["serviceAccount:${local.deployer_sa_email}"]
    "roles/eventarc.admin"          = ["serviceAccount:${local.deployer_sa_email}"]
    "roles/iam.serviceAccountAdmin" = ["serviceAccount:${local.deployer_sa_email}"]
    "roles/logging.admin"           = ["serviceAccount:${local.deployer_sa_email}"]
    "roles/artifactregistry.writer" = ["serviceAccount:${local.deployer_sa_email}", "serviceAccount:${local.cloud_build_sa}"]
    "roles/logging.logWriter"       = ["serviceAccount:${local.cloud_build_sa}"]
  }

  sa_act_as = {}

  depends_on = [module.services]
}

# Secrets (if using Mailgun or other secrets)
module "secrets" {
  source     = "../../modules/secrets"
  project_id = var.project_id

  secrets = var.mailgun_api_key != "" ? {
    "mailgun_api_key${var.environment == "prod" ? "" : "_${var.environment}"}" = {
      secret_data = var.mailgun_api_key
      labels      = local.labels
    }
  } : {}

  secret_accessors = var.mailgun_api_key != "" ? {
    "mailgun_api_key${var.environment == "prod" ? "" : "_${var.environment}"}" = [module.runtime_sa.email]
  } : {}

  depends_on = [module.services, module.runtime_sa]
}

# Function source upload (assumes zip exists at specified path)
module "function_source" {
  source      = "../../modules/function_source"
  bucket_name = module.source_bucket.name
  object_name = var.source_object_name
  source_path = var.source_zip_path
}

# Cloud Function
module "function" {
  source                = "../../modules/gcf2_function"
  name                  = var.environment == "prod" ? var.function_name : "${var.function_name}-${var.environment}"
  region                = var.region
  project_id            = var.project_id
  service_account_email = module.runtime_sa.email
  topic_id              = module.topic.id
  source_bucket         = module.function_source.bucket
  source_object         = module.function_source.object
  entry_point           = "emailHandler"
  runtime               = "nodejs22"
  available_memory      = var.available_memory
  timeout_seconds       = var.timeout_seconds
  min_instance_count    = var.min_instance_count
  max_instance_count    = var.max_instance_count
  labels                = local.labels

  env_vars = merge(
    {
      NODE_ENV   = var.environment == "prod" ? "production" : var.environment
      EMAIL_FROM = var.environment == "prod" ? "Sol Software <notifications@solsoftware.co>" : "Sol Software Test <test@solsoftware.co>"
    },
    var.env_vars
  )

  secret_env_vars = var.mailgun_api_key != "" ? {
    MAILGUN_API_KEY = {
      secret  = "mailgun_api_key${var.environment == "prod" ? "" : "_${var.environment}"}"
      version = "latest"
    }
  } : {}

  depends_on = [
    module.services,
    module.function_source,
    module.iam,
    module.secrets
  ]
}

# Allow compute SA to invoke the function
resource "google_cloud_run_v2_service_iam_member" "trigger_invoker" {
  project  = var.project_id
  location = var.region
  name     = var.environment == "prod" ? var.function_name : "${var.function_name}-${var.environment}"
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.compute_default_sa}"
  
  depends_on = [module.function]
}

# Grant runtime SA logging permissions
resource "google_project_iam_member" "runtime_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${module.runtime_sa.email}"
  
  depends_on = [module.runtime_sa]
}

# Allow deployer SA to act as runtime SA
resource "google_service_account_iam_member" "deployer_act_as_runtime" {
  service_account_id = module.runtime_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.deployer_sa_email}"
  
  depends_on = [module.runtime_sa]
}
