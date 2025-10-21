# Sol Infrastructure (sol-infra)

Centralized infrastructure repository for Sol Software microservices using **Terragrunt** for DRY configuration.

## 🎯 Key Features

- **DRY Configuration** - Write infrastructure code once, use everywhere
- **Terragrunt-Powered** - Minimal duplication between environments
- **Multi-Environment** - Easy test/prod/staging management
- **Reusable Modules** - Battle-tested Terraform modules
- **Production Ready** - Remote state, IAM, secrets management

## Structure

```
sol-infra/
├── terragrunt.hcl                 # Root Terragrunt config
├── modules/                        # Reusable Terraform modules
│   ├── gcs_bucket/                # GCS bucket with IAM
│   ├── gcf2_function/             # Cloud Functions v2
│   ├── pubsub_topic/              # Pub/Sub topic with IAM
│   ├── service_account/           # Service account creation
│   ├── project_services/          # Enable GCP APIs
│   ├── iam_bindings/              # Centralized IAM management
│   ├── function_source/           # Function source upload
│   └── secrets/                   # Secret Manager configuration
├── service-modules/                # Service Terraform (shared across envs)
│   ├── sol-email-service/         # Email service infrastructure
│   └── sol-analytics-service/     # Analytics service infrastructure
└── live/                           # Environment configurations
    ├── test/
    │   ├── env.hcl                # Test environment defaults
    │   ├── sol-email-service/
    │   │   └── terragrunt.hcl     # Just overrides!
    │   └── sol-analytics-service/
    │       └── terragrunt.hcl
    └── prod/
        ├── env.hcl                # Prod environment defaults
        ├── sol-email-service/
        │   └── terragrunt.hcl
        └── sol-analytics-service/
            └── terragrunt.hcl
```

## Modules

### GCS Bucket
Creates GCS buckets with lifecycle policies and IAM bindings.

### GCF2 Function
Deploys Cloud Functions v2 with Pub/Sub triggers.

### Pub/Sub Topic
Creates Pub/Sub topics with publisher IAM bindings.

### Service Account
Creates service accounts with actAs permissions.

### Project Services
Enables required GCP APIs for the project.

### IAM Bindings
Centralized IAM management for projects, service accounts, and secrets.

### Function Source
Uploads function source code to GCS.

### Secrets
Manages Secret Manager secrets and access permissions.

## Quick Start

### Prerequisites

- **Terraform** >= 1.0: `brew install terraform`
- **Terragrunt** >= 0.50: `brew install terragrunt`
- **GCP CLI**: `gcloud auth application-default login`

### Deploying Infrastructure

1. Navigate to the service environment:
   ```bash
   cd live/prod/sol-email-service
   ```

2. Initialize Terragrunt:
   ```bash
   terragrunt init
   ```

3. Review the plan:
   ```bash
   terragrunt plan
   ```

4. Apply the configuration:
   ```bash
   terragrunt apply
   ```

### Using the Makefile

```bash
# Deploy single service
make apply SERVICE=sol-email-service ENV=test

# Deploy all services in test
make run-all-apply ENV=test

# Other commands
make plan SERVICE=sol-email-service ENV=prod
make output SERVICE=sol-analytics-service ENV=test
```

### Variable Configuration

Each environment has its own `variables.tf` file with environment-specific defaults. Override these using:
- `terraform.tfvars` file (for sensitive values, add to `.gitignore`)
- Command-line flags: `terraform apply -var="project_id=my-project"`
- Environment variables: `TF_VAR_project_id=my-project`

## Why Terragrunt?

**Before Terragrunt:**
- Each environment = ~700 lines of duplicated Terraform code
- Changes require updating test AND prod files
- Easy to have config drift between environments

**After Terragrunt:**
- Infrastructure code written ONCE in `service-modules/`
- Each environment = ~30 lines of overrides
- 44% less code, zero duplication

See [TERRAGRUNT_GUIDE.md](./TERRAGRUNT_GUIDE.md) for complete details.

## Calling from Existing Projects

### CI/CD Integration (Recommended)

```yaml
# GitHub Actions example
- name: Setup Terragrunt
  run: |
    brew install terragrunt  # or download binary

- name: Deploy to prod
  run: |
    cd live/prod/sol-email-service
    terragrunt apply -auto-approve
```

### Local Development

```bash
# Clone and navigate
git clone <sol-infra-repo> ~/sol-infra
cd ~/sol-infra/live/test/sol-email-service

# Deploy
terragrunt init
terragrunt apply
```

## Best Practices

1. **Never commit sensitive values** - Use Secret Manager or environment variables
2. **Use consistent naming** - Follow the pattern: `{project-id}-{service}-{resource}`
3. **Tag resources** - All resources include `app`, `env`, and `managed_by` labels
4. **Remote state** - Always use remote state for production environments
5. **Version modules** - When modules stabilize, consider versioning via Git tags

## Migration from Existing Infrastructure

To migrate from your existing infra directories:

1. **Review current state**: Export existing resources using `terraform state pull`
2. **Import resources**: Use `terraform import` for existing resources
3. **Update CI/CD**: Point deployment pipelines to sol-infra paths
4. **Test in dev**: Validate changes in test environment first
5. **Clean up**: Remove old infra directories after successful migration

## Documentation

- **[TERRAGRUNT_GUIDE.md](./TERRAGRUNT_GUIDE.md)** - Complete Terragrunt usage guide
- **[QUICK_START.md](./QUICK_START.md)** - 5-minute deployment guide
- **[USAGE_GUIDE.md](./USAGE_GUIDE.md)** - Terraform-based usage (legacy)
- **[MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)** - Migration from old infrastructure
- **[STRUCTURE.md](./STRUCTURE.md)** - Repository structure details

## Key Files

- `terragrunt.hcl` - Root configuration (provider, remote state)
- `live/{env}/env.hcl` - Environment defaults (memory, instances, lifecycle)
- `live/{env}/{service}/terragrunt.hcl` - Service environment config (just overrides!)
- `service-modules/{service}/` - Shared Terraform code
- `modules/` - Reusable Terraform modules

## Support

For questions or issues:
- Check the [TERRAGRUNT_GUIDE.md](./TERRAGRUNT_GUIDE.md)
- Review Terragrunt docs: https://terragrunt.gruntwork.io/
- Contact the infrastructure team
