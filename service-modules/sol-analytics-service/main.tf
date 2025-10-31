# Sol Analytics Service Infrastructure
# This module is shared across all environments

locals {
  deployer_sa_email     = "tf-deployer@${var.project_id}.iam.gserviceaccount.com"
  topic_name            = "${var.function_name}-topic"
  artifacts_bucket_name = "${var.project_id}-${var.function_name}-artifacts${var.environment == "prod" ? "" : "-${var.environment}"}"
  
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
    "analyticsdata.googleapis.com",
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

  secret_bindings = var.secret_bindings

  depends_on = [module.services]
}

# Pub/Sub topic for analytics events
module "topic" {
  source        = "../../modules/pubsub_topic"
  name          = local.topic_name
  labels        = local.labels
  publisher_sas = var.publisher_sas
  
  depends_on = [module.services]
}

# Artifacts bucket (for processed analytics data)
module "artifacts_bucket" {
  source                = "../../modules/gcs_bucket"
  name                  = local.artifacts_bucket_name
  location              = var.region
  force_destroy         = true
  labels                = local.labels
  lifecycle_days_delete = var.lifecycle_days_delete
  iam_writers           = []
  iam_readers           = tolist(var.artifact_reader_sas)
  iam_deleters          = []
  
  depends_on = [module.services]
}

# Source bucket for function code
module "source_bucket" {
  source        = "../../modules/gcs_bucket"
  name          = "${var.project_id}-${var.function_name}-gcf-src${var.environment == "prod" ? "" : "-${var.environment}"}"
  location      = var.region
  force_destroy = true
  labels        = local.labels
  
  depends_on = [module.services]
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
  entry_point           = "analyticsHandler"
  runtime               = "nodejs22"
  available_memory      = var.available_memory
  timeout_seconds       = var.timeout_seconds
  min_instance_count    = var.min_instance_count
  max_instance_count    = var.max_instance_count
  labels                = local.labels

  env_vars = merge(
    {
      NODE_ENV         = var.environment == "prod" ? "production" : var.environment
      BUCKET_ARTIFACTS = local.artifacts_bucket_name
    },
    var.env_vars
  )

  secret_env_vars = var.secret_env_vars

  depends_on = [
    module.services,
    module.function_source,
    module.iam
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

# Grant runtime SA access to artifacts bucket
resource "google_storage_bucket_iam_member" "runtime_sa_artifacts_writer" {
  bucket = module.artifacts_bucket.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${module.runtime_sa.email}"
  
  depends_on = [module.runtime_sa, module.artifacts_bucket]
}

resource "google_storage_bucket_iam_member" "runtime_sa_artifacts_reader" {
  bucket = module.artifacts_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.runtime_sa.email}"
  
  depends_on = [module.runtime_sa, module.artifacts_bucket]
}

resource "google_storage_bucket_iam_member" "runtime_sa_artifacts_deleter" {
  bucket = module.artifacts_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.runtime_sa.email}"
  
  depends_on = [module.runtime_sa, module.artifacts_bucket]
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
