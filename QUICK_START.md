# Quick Start Guide

Get up and running with sol-infra in 5 minutes.

## Prerequisites

- Terraform >= 1.0 installed
- GCP account with appropriate permissions
- gcloud CLI authenticated

## Step 1: Choose Your Service

Navigate to the project environment you want to deploy:

```bash
cd projects/sol-email-service/test
# or
cd projects/sol-analytics-service/test
```

## Step 2: Configure Variables

Copy the example variables file:

```bash
cp ../terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
project_id     = "your-gcp-project"
project_number = "123456789"
```

## Step 3: Prepare Function Source

Create a zip file of your function source code:

```bash
# Example for email service
cd /path/to/sol-email-service/function-source
zip -r function.zip .
```

Update the source path in `terraform.tfvars`:

```hcl
source_zip_path = "/path/to/function.zip"
```

## Step 4: Deploy

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply
```

## Step 5: Verify

Check the outputs:

```bash
terraform output
```

Test your function:

```bash
# Publish a test message to the topic
gcloud pubsub topics publish $(terraform output -raw topic_name) \
  --message='{"test": "message"}'

# Check function logs
gcloud functions logs read $(terraform output -raw function_name) \
  --region=us-central1 \
  --limit=10
```

## What's Next?

- Read the full [USAGE_GUIDE.md](./USAGE_GUIDE.md)
- Set up CI/CD integration
- Configure remote state storage
- Deploy to production environment

## Common Commands

```bash
# View current state
terraform show

# List resources
terraform state list

# Update specific resource
terraform apply -target=module.function

# Destroy everything (careful!)
terraform destroy
```

## Getting Help

- Check [USAGE_GUIDE.md](./USAGE_GUIDE.md) for detailed workflows
- See [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) for migrating existing infrastructure
- Review module documentation in `modules/*/main.tf`
