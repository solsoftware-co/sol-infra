# Sol Infrastructure Usage Guide

## Quick Start

### Prerequisites

1. **Terraform installed** (>= 1.0)
   ```bash
   terraform -v
   ```

2. **GCP authentication**
   ```bash
   gcloud auth application-default login
   ```

3. **Function source code** packaged as a zip file

### Deploy Your First Environment

#### Example: Deploying sol-email-service to test environment

1. **Navigate to the test environment**
   ```bash
   cd projects/sol-email-service/test
   ```

2. **Create a terraform.tfvars file** (optional, for overrides)
   ```hcl
   project_id       = "your-gcp-project-id"
   project_number   = "your-project-number"
   mailgun_api_key  = "your-mailgun-key"  # Keep this file gitignored!
   
   # Override source path if needed
   source_zip_path = "/path/to/your/function.zip"
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review the plan**
   ```bash
   terraform plan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply
   ```

6. **View outputs**
   ```bash
   terraform output
   ```

## Integration with Existing Projects

### Option 1: CI/CD Integration (Recommended)

Add a deployment step to your existing service's CI/CD pipeline:

**GitHub Actions Example:**

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths:
      - 'function-source/**'

jobs:
  deploy-infra:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout service repo
        uses: actions/checkout@v3
        with:
          path: service
      
      - name: Checkout sol-infra
        uses: actions/checkout@v3
        with:
          repository: sol-software/sol-infra
          path: sol-infra
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Build function zip
        run: |
          cd service/function-source
          zip -r ../../function.zip .
      
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}
      
      - name: Deploy to prod
        run: |
          cd sol-infra/projects/sol-email-service/prod
          terraform init
          terraform apply -auto-approve \
            -var="source_zip_path=../../../../function.zip" \
            -var="source_object_name=function-${GITHUB_SHA}.zip" \
            -var="mailgun_api_key=${{ secrets.MAILGUN_API_KEY }}"
```

### Option 2: Local Development

For local testing and development:

```bash
# 1. Clone both repos side-by-side
git clone <your-service-repo> ~/projects/sol-email-service
git clone <sol-infra-repo> ~/projects/sol-infra

# 2. Build your function
cd ~/projects/sol-email-service/function-source
zip -r ../function.zip .

# 3. Deploy to test environment
cd ~/projects/sol-infra/projects/sol-email-service/test
terraform init
terraform apply -var="source_zip_path=../../../../sol-email-service/function.zip"
```

### Option 3: Monorepo Structure

If you prefer a monorepo:

```
sol-software/
├── sol-infra/                    # Infrastructure code
│   ├── modules/
│   └── projects/
├── sol-email-service/            # Service code
│   └── function-source/
└── sol-analytics-service/
    └── function-source/
```

Then use relative paths in your `terraform.tfvars`:

```hcl
source_zip_path = "../../../../sol-email-service/function.zip"
```

## Common Workflows

### Updating Function Code

When you update your function code:

```bash
# 1. Build new zip
cd ~/projects/sol-email-service/function-source
zip -r ../function.zip .

# 2. Apply changes (Terraform will detect the new zip)
cd ~/projects/sol-infra/projects/sol-email-service/prod
terraform apply -var="source_zip_path=../../../../sol-email-service/function.zip"
```

### Adding a New Secret

1. **Create the secret manually in GCP** (recommended) or use the secrets module
2. **Update your environment configuration** to reference it:

```hcl
# In your main.tf or terraform.tfvars
secret_env_vars = {
  MY_SECRET = {
    secret  = "my-secret-name"
    version = "latest"
  }
}
```

3. **Apply the changes**
   ```bash
   terraform apply
   ```

### Switching Environments

Deploy the same code to different environments:

```bash
# Test environment
cd projects/sol-email-service/test
terraform apply -var="source_zip_path=/path/to/function.zip"

# After testing, deploy to prod
cd ../prod
terraform apply -var="source_zip_path=/path/to/function.zip"
```

## Environment Variables

Each environment can have different variables:

**Test Environment** (`test/terraform.tfvars`):
```hcl
project_id     = "sol-infra-test"
function_name  = "sol-email-service"
env_vars = {
  DEBUG = "true"
  LOG_LEVEL = "debug"
}
```

**Prod Environment** (`prod/terraform.tfvars`):
```hcl
project_id     = "sol-infra-prod"
function_name  = "sol-email-service"
env_vars = {
  DEBUG = "false"
  LOG_LEVEL = "info"
}
```

## Remote State Configuration

For production, configure remote state storage:

1. **Create a GCS bucket for state**
   ```bash
   gsutil mb gs://sol-terraform-state
   gsutil versioning set on gs://sol-terraform-state
   ```

2. **Update providers.tf** in each environment:
   ```hcl
   terraform {
     backend "gcs" {
       bucket = "sol-terraform-state"
       prefix = "sol-email-service/prod"
     }
   }
   ```

3. **Re-initialize Terraform**
   ```bash
   terraform init -migrate-state
   ```

## Troubleshooting

### Issue: "Error creating Function: Permission denied"

**Solution:** Ensure your deployer service account has the necessary permissions:
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:tf-deployer@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudfunctions.admin"
```

### Issue: "Source zip not found"

**Solution:** Verify the `source_zip_path` variable points to the correct location:
```bash
terraform apply -var="source_zip_path=/absolute/path/to/function.zip"
```

### Issue: "Backend configuration changed"

**Solution:** Re-initialize Terraform:
```bash
terraform init -reconfigure
```

## Best Practices

1. **Never commit sensitive values** - Use environment variables or secret management
2. **Use remote state for production** - Prevents concurrent modifications
3. **Test in test environment first** - Always validate changes before production
4. **Version your infrastructure** - Use Git tags for infrastructure releases
5. **Document custom configurations** - Keep a README in each project's directory
6. **Use consistent naming** - Follow the pattern: `{service}-{resource}-{env}`

## Next Steps

- Set up automated deployments via CI/CD
- Configure monitoring and alerting
- Implement cost tracking with labels
- Add custom modules for project-specific needs
