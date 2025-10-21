# Migration Guide: Moving from Service Infra to sol-infra

This guide walks you through migrating your existing infrastructure from service-specific directories to the centralized `sol-infra` repository.

## Pre-Migration Checklist

- [ ] Backup current Terraform state files
- [ ] Document current infrastructure (resources, variables, secrets)
- [ ] Test deployment in a dev/test environment first
- [ ] Coordinate with team to avoid concurrent changes
- [ ] Ensure you have GCP admin access

## Migration Strategy

We'll use a **gradual migration** approach to minimize risk:

1. Deploy new infrastructure alongside old (test environment)
2. Verify functionality
3. Migrate production with state import
4. Decommission old infrastructure

## Step 1: Export Existing State

Before making any changes, export your current Terraform state:

```bash
# For sol-email-service
cd ~/projects/sol-email-service/infra
terraform state pull > ~/backup/email-service-state-backup.json

# For sol-analytics-service
cd ~/projects/sol-analytics-service/infra/env/prod
terraform state pull > ~/backup/analytics-service-state-backup.json
```

## Step 2: Deploy to Test Environment (New Infrastructure)

This creates new resources to verify everything works:

```bash
# Clone sol-infra repo
git clone <sol-infra-repo> ~/projects/sol-infra

# Build your function zip
cd ~/projects/sol-email-service/function-source
zip -r ../function.zip .

# Deploy to new test environment
cd ~/projects/sol-infra/projects/sol-email-service/test
terraform init
terraform apply -var="source_zip_path=../../../../sol-email-service/function.zip"
```

**Verify the deployment:**
- Function is created and accessible
- Pub/Sub topic receives messages
- IAM permissions are correct
- Secrets are accessible

## Step 3: Production Migration Options

Choose one of these approaches:

### Option A: Fresh Deployment (Recommended for small services)

Deploy new infrastructure and cut over:

```bash
cd ~/projects/sol-infra/projects/sol-email-service/prod

# Deploy new infrastructure
terraform init
terraform apply -var="source_zip_path=path/to/function.zip"

# Update any external systems to use new resources (e.g., topic names)
# Test thoroughly

# Once verified, destroy old infrastructure
cd ~/projects/sol-email-service/infra
terraform destroy
```

### Option B: State Import (Recommended for production services)

Import existing resources into new Terraform configuration:

```bash
cd ~/projects/sol-infra/projects/sol-email-service/prod

# Initialize
terraform init

# Create a plan to see what Terraform wants to create
terraform plan -var="source_zip_path=path/to/function.zip" -out=plan.out

# For each resource that already exists, import it
# Example for the function:
terraform import 'module.function.google_cloudfunctions2_function.this' \
  projects/PROJECT_ID/locations/REGION/functions/FUNCTION_NAME

# Example for the topic:
terraform import 'module.topic.google_pubsub_topic.this' \
  projects/PROJECT_ID/topics/TOPIC_NAME

# Example for service account:
terraform import 'module.runtime_sa.google_service_account.this' \
  projects/PROJECT_ID/serviceAccounts/SA_EMAIL

# After importing all resources, verify no changes needed
terraform plan -var="source_zip_path=path/to/function.zip"
```

**Resources to potentially import:**
- Cloud Functions
- Service Accounts
- Pub/Sub Topics
- GCS Buckets
- IAM bindings
- Secrets

### Option C: Hybrid Approach

Import critical resources, recreate less critical ones:

**Critical resources to import:**
- Service Accounts (to preserve permissions)
- Pub/Sub Topics (to preserve subscriptions)
- Secrets (to avoid downtime)

**Resources safe to recreate:**
- Cloud Functions (can be redeployed)
- GCS Buckets (if empty or backed up)
- IAM bindings (can be reapplied)

## Step 4: Update CI/CD Pipelines

Update your deployment pipelines to use the new structure:

**Before:**
```yaml
- name: Deploy
  run: |
    cd infra
    terraform apply
```

**After:**
```yaml
- name: Build function
  run: |
    cd function-source
    zip -r ../function.zip .

- name: Deploy
  run: |
    cd ../sol-infra/projects/sol-email-service/prod
    terraform apply -var="source_zip_path=../../../../sol-email-service/function.zip"
```

## Step 5: Clean Up Old Infrastructure

Once everything is working:

```bash
# Remove old infra directories from your service repos
cd ~/projects/sol-email-service
rm -rf infra/

# Commit and push
git add .
git commit -m "Migrate infrastructure to sol-infra repository"
git push
```

## Service-Specific Migration Notes

### sol-email-service

**Key differences:**
- Function name remains the same in prod
- Test environment adds `-test` suffix
- Secrets use the `secrets` module instead of inline
- IAM uses centralized `iam_bindings` module

**Migration steps:**
1. Import service account
2. Import Pub/Sub topic
3. Import Cloud Function
4. Import secret (if exists)
5. Verify IAM bindings

**Import commands:**
```bash
cd ~/projects/sol-infra/projects/sol-email-service/prod

terraform import 'module.runtime_sa.google_service_account.this' \
  projects/sol-infra/serviceAccounts/sol-email-service-sa@sol-infra.iam.gserviceaccount.com

terraform import 'module.topic.google_pubsub_topic.this' \
  projects/sol-infra/topics/sol-email-service-topic

terraform import 'module.function.google_cloudfunctions2_function.this' \
  projects/sol-infra/locations/us-central1/functions/sol-email-service
```

### sol-analytics-service

**Key differences:**
- Adds artifacts bucket for analytics data
- Uses `analyticsHandler` entry point
- Longer timeout (540s)
- Analytics API enabled

**Migration steps:**
1. Import service account
2. Import Pub/Sub topic
3. Import Cloud Function
4. Import source bucket
5. Import or create artifacts bucket
6. Verify IAM bindings

**Import commands:**
```bash
cd ~/projects/sol-infra/projects/sol-analytics-service/prod

terraform import 'module.runtime_sa.google_service_account.this' \
  projects/sol-infra/serviceAccounts/sol-analytics-service-sa@sol-infra.iam.gserviceaccount.com

terraform import 'module.topic.google_pubsub_topic.this' \
  projects/sol-infra/topics/sol-analytics-service-topic

terraform import 'module.function.google_cloudfunctions2_function.this' \
  projects/sol-infra/locations/us-central1/functions/sol-analytics-service

terraform import 'module.artifacts_bucket.google_storage_bucket.this' \
  sol-infra-sol-analytics-service-artifacts
```

## Rollback Plan

If migration fails, you can rollback:

1. **Stop using new infrastructure**
   ```bash
   cd ~/projects/sol-infra/projects/SERVICE_NAME/prod
   terraform destroy
   ```

2. **Revert to old infrastructure**
   ```bash
   cd ~/projects/SERVICE_NAME/infra
   terraform apply
   ```

3. **Restore state from backup if needed**
   ```bash
   terraform state push ~/backup/SERVICE-state-backup.json
   ```

## Verification Checklist

After migration, verify:

- [ ] Function deploys successfully
- [ ] Function responds to Pub/Sub messages
- [ ] Logs are accessible in Cloud Logging
- [ ] Secrets are accessible by the function
- [ ] IAM permissions are correct
- [ ] No resources are duplicated
- [ ] CI/CD pipeline works
- [ ] Monitoring and alerts still function

## Common Issues

### Issue: Resource already exists

**Cause:** Resource wasn't imported before `terraform apply`

**Solution:** Import the resource:
```bash
terraform import 'module.MODULE.RESOURCE.this' RESOURCE_ID
```

### Issue: State conflicts

**Cause:** Multiple state files or concurrent operations

**Solution:** Use remote state and locking:
```hcl
terraform {
  backend "gcs" {
    bucket = "sol-terraform-state"
    prefix = "SERVICE/ENV"
  }
}
```

### Issue: Permission denied

**Cause:** Service account lacks permissions

**Solution:** Grant necessary roles:
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="ROLE"
```

## Support

If you encounter issues during migration:

1. Check the [USAGE_GUIDE.md](./USAGE_GUIDE.md)
2. Review Terraform logs: `TF_LOG=DEBUG terraform apply`
3. Contact the infrastructure team
4. Keep backups until migration is fully verified

## Timeline Recommendation

- **Week 1:** Deploy to test environments, verify functionality
- **Week 2:** Update CI/CD pipelines, test deployments
- **Week 3:** Migrate production (one service at a time)
- **Week 4:** Monitor, optimize, clean up old infrastructure
