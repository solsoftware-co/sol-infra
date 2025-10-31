# Bootstrap Infrastructure

This directory contains Terraform configuration for bootstrapping the infrastructure required to deploy and manage the sol-infra project. It should be applied **once per environment** using admin credentials before any other infrastructure is deployed.

## What This Creates

1. **Service Account** (`tf-deployer`) - Used by CI/CD pipelines to deploy infrastructure
2. **IAM Permissions** - Grants the service account necessary permissions:
   - `roles/storage.admin` - Manage Terraform state in GCS
   - `roles/cloudfunctions.admin` - Deploy Cloud Functions
   - `roles/iam.serviceAccountUser` - Use service accounts in deployments
   - `roles/serviceusage.serviceUsageAdmin` - Enable/manage GCP APIs
3. **State Bucket** - GCS bucket for storing Terraform state with versioning enabled

## Prerequisites

- Admin access to the target GCP project
- `gcloud` CLI authenticated with admin credentials
- Terraform >= 1.0 installed

## Initial Setup

### 1. Authenticate with Admin Credentials

```bash
gcloud auth application-default login
```

### 2. Create Environment-Specific Variables File

Copy the example file for your environment:

```bash
# For test environment
cp test.tfvars.example test.tfvars

# For prod environment
cp prod.tfvars.example prod.tfvars
```

Edit the `.tfvars` file with your actual project ID if different from the example.

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
# For test environment
terraform plan -var-file=test.tfvars

# For prod environment
terraform plan -var-file=prod.tfvars
```

### 5. Apply the Configuration

```bash
# For test environment
terraform apply -var-file=test.tfvars

# For prod environment
terraform apply -var-file=prod.tfvars
```

### 6. Save the Outputs

After applying, save the service account email for use in CI/CD:

```bash
terraform output tf_deployer_email
```

## Importing Existing Resources

If you've already created the service account and permissions manually (as you did for test), you can import them into Terraform state to avoid drift:

### Import the Service Account

```bash
terraform import -var-file=test.tfvars \
  google_service_account.tf_deployer \
  projects/sol-infra-test/serviceAccounts/tf-deployer@sol-infra-test.iam.gserviceaccount.com
```

### Import IAM Bindings

```bash
# Storage Admin
terraform import -var-file=test.tfvars \
  google_project_iam_member.tf_deployer_storage_admin \
  "sol-infra-test roles/storage.admin serviceAccount:tf-deployer@sol-infra-test.iam.gserviceaccount.com"

# Cloud Functions Admin
terraform import -var-file=test.tfvars \
  google_project_iam_member.tf_deployer_cloudfunctions_admin \
  "sol-infra-test roles/cloudfunctions.admin serviceAccount:tf-deployer@sol-infra-test.iam.gserviceaccount.com"

# Service Account User
terraform import -var-file=test.tfvars \
  google_project_iam_member.tf_deployer_sa_user \
  "sol-infra-test roles/iam.serviceAccountUser serviceAccount:tf-deployer@sol-infra-test.iam.gserviceaccount.com"

# Service Usage Admin
terraform import -var-file=test.tfvars \
  google_project_iam_member.tf_deployer_service_usage_admin \
  "sol-infra-test roles/serviceusage.serviceUsageAdmin serviceAccount:tf-deployer@sol-infra-test.iam.gserviceaccount.com"
```

### Import the State Bucket (if it exists)

```bash
terraform import -var-file=test.tfvars \
  google_storage_bucket.tfstate \
  sol-infra-test-tfstate
```

After importing, run `terraform plan` to verify there are no changes needed.

## Using the Service Account in CI/CD

### GitHub Actions

1. Create a service account key (or use Workload Identity Federation - recommended):

```bash
gcloud iam service-accounts keys create key.json \
  --iam-account=tf-deployer@sol-infra-test.iam.gserviceaccount.com
```

2. Add the key as a GitHub secret named `GCP_SA_KEY`

3. In your workflow, authenticate:

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v1
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}
```

### Local Development

To use the service account locally for testing:

```bash
gcloud auth activate-service-account \
  --key-file=key.json

export GOOGLE_APPLICATION_CREDENTIALS=key.json
```

## Maintenance

### Adding New Permissions

If you need to grant additional permissions to the tf-deployer service account:

1. Add a new `google_project_iam_member` resource in `service-accounts.tf`
2. Run `terraform plan` and `terraform apply`

### Rotating Service Account Keys

Service account keys should be rotated regularly:

```bash
# Create new key
gcloud iam service-accounts keys create new-key.json \
  --iam-account=tf-deployer@sol-infra-test.iam.gserviceaccount.com

# Update CI/CD secrets with new key

# Delete old key
gcloud iam service-accounts keys delete KEY_ID \
  --iam-account=tf-deployer@sol-infra-test.iam.gserviceaccount.com
```

## State Management

This bootstrap configuration uses **local state** by default since it creates the remote state bucket. After initial setup, you can optionally migrate to remote state:

1. Uncomment and configure the GCS backend in `versions.tf`
2. Run `terraform init -migrate-state`

However, keeping bootstrap state local is often preferred to avoid circular dependencies.

## Troubleshooting

### Permission Denied Errors

If you get permission denied errors during apply:
- Ensure you're authenticated with admin credentials
- Verify your account has `roles/owner` or equivalent permissions on the project

### Resource Already Exists

If resources already exist:
- Use the import commands above to bring them under Terraform management
- Or delete the existing resources and let Terraform recreate them

### State Bucket Already Exists

If the state bucket already exists and you get a conflict:
- Import it using the command in the "Import the State Bucket" section
- Or use a different bucket name by modifying the `project_id` variable
