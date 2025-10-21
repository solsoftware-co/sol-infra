# Sol-Infra Repository Structure

This document provides a complete overview of the repository structure.

```
sol-infra/
│
├── .github/
│   └── workflows/
│       ├── deploy-example.yml          # Example deployment workflow
│       └── terraform-checks.yml        # Terraform validation CI
│
├── modules/                             # Reusable Terraform modules
│   ├── gcs_bucket/
│   │   └── main.tf                     # GCS bucket with IAM and lifecycle
│   ├── gcf2_function/
│   │   └── main.tf                     # Cloud Functions v2 (Pub/Sub)
│   ├── pubsub_topic/
│   │   └── main.tf                     # Pub/Sub topics with publishers
│   ├── service_account/
│   │   └── main.tf                     # Service account creation
│   ├── project_services/
│   │   └── main.tf                     # Enable GCP APIs
│   ├── iam_bindings/
│   │   └── main.tf                     # Centralized IAM management
│   ├── function_source/
│   │   └── main.tf                     # Function source upload
│   └── secrets/
│       └── main.tf                     # Secret Manager configuration
│
├── projects/                            # Environment-specific configs
│   ├── sol-email-service/
│   │   ├── terraform.tfvars.example    # Example variables
│   │   ├── test/
│   │   │   ├── main.tf                 # Test environment main config
│   │   │   ├── variables.tf            # Test environment variables
│   │   │   ├── providers.tf            # Terraform & provider config
│   │   │   └── outputs.tf              # Output values
│   │   └── prod/
│   │       ├── main.tf                 # Prod environment main config
│   │       ├── variables.tf            # Prod environment variables
│   │       ├── providers.tf            # Terraform & provider config
│   │       └── outputs.tf              # Output values
│   │
│   └── sol-analytics-service/
│       ├── terraform.tfvars.example    # Example variables
│       ├── test/
│       │   ├── main.tf                 # Test environment main config
│       │   ├── variables.tf            # Test environment variables
│       │   ├── providers.tf            # Terraform & provider config
│       │   └── outputs.tf              # Output values
│       └── prod/
│           ├── main.tf                 # Prod environment main config
│           ├── variables.tf            # Prod environment variables
│           ├── providers.tf            # Terraform & provider config
│           └── outputs.tf              # Output values
│
├── .gitignore                           # Git ignore rules
├── Makefile                             # Convenience commands
├── README.md                            # Main repository README
├── QUICK_START.md                       # 5-minute quick start guide
├── USAGE_GUIDE.md                       # Detailed usage documentation
├── MIGRATION_GUIDE.md                   # Migration from old infra
└── STRUCTURE.md                         # This file

```

## Module Descriptions

### gcs_bucket
Creates GCS buckets with:
- Uniform bucket-level access
- Lifecycle policies for automatic deletion
- IAM bindings for writers, readers, and deleters
- Configurable location and labels

**Inputs:** name, location, force_destroy, labels, lifecycle_days_delete, iam_writers, iam_readers, iam_deleters

**Outputs:** name, url

### gcf2_function
Deploys Cloud Functions v2 with:
- Pub/Sub event triggers
- Configurable runtime and memory
- Environment variables (plain and secret)
- Service account association
- Ingress settings

**Inputs:** name, region, project_id, service_account_email, topic_id, source_bucket, source_object, entry_point, runtime, available_memory, timeout_seconds, min_instance_count, max_instance_count, ingress_settings, env_vars, secret_env_vars, labels

**Outputs:** name, uri, id

### pubsub_topic
Creates Pub/Sub topics with:
- Message retention configuration
- IAM bindings for publishers
- Labeling support

**Inputs:** name, labels, publisher_sas, message_retention_duration

**Outputs:** id, name

### service_account
Creates service accounts with:
- Configurable display name
- actAs permissions for deployer SA

**Inputs:** project_id, account_id, display_name, deployer_sa_email

**Outputs:** email, id, name

### project_services
Enables GCP APIs including:
- Cloud Functions
- Cloud Run
- Eventarc
- Pub/Sub
- Cloud Build
- Artifact Registry
- Logging
- Secret Manager
- Cloud Storage

**Inputs:** project_id, services, disable_on_destroy

**Outputs:** enabled_services

### iam_bindings
Centralized IAM management for:
- Project-level role bindings
- Service account actAs permissions
- Secret Manager access
- Cloud Run invoker permissions

**Inputs:** project_id, region, project_roles, sa_act_as, secret_bindings, run_invokers

**Outputs:** None (creates IAM bindings)

### function_source
Uploads function source code to GCS:
- Handles zip file uploads
- Tracks object generation for versioning

**Inputs:** bucket_name, object_name, source_path

**Outputs:** bucket, object, generation

### secrets
Manages Secret Manager secrets:
- Creates secrets with automatic replication
- Manages secret versions
- Configures accessor permissions

**Inputs:** project_id, secrets, secret_accessors

**Outputs:** secret_ids

## Project Configurations

Each service has two environments:

### Test Environment
- Lower resource limits (256M memory, 1 max instance)
- Shorter lifecycle policies (7 days)
- `-test` suffix on resources
- Separate service accounts
- Test-specific secrets

### Production Environment
- Production resource limits (512M memory, 3 max instances)
- Standard lifecycle policies (30 days)
- Production service accounts
- Production secrets

## File Descriptions

### .gitignore
Excludes:
- Terraform state files
- `.terraform/` directories
- Variable files with sensitive data
- Lock files
- Function source zips
- IDE and OS files

### Makefile
Provides commands for:
- `init` - Initialize Terraform
- `plan` - Show execution plan
- `apply` - Apply configuration
- `destroy` - Destroy infrastructure
- `fmt` - Format Terraform files
- `validate` - Validate configuration
- `clean` - Remove cache directories

### README.md
Main repository documentation including:
- Overall structure
- Module descriptions
- Usage instructions
- Best practices

### QUICK_START.md
5-minute guide covering:
- Prerequisites
- Basic deployment steps
- Verification commands

### USAGE_GUIDE.md
Comprehensive guide including:
- Integration options (CI/CD, local, monorepo)
- Common workflows
- Environment variable configuration
- Remote state setup
- Troubleshooting

### MIGRATION_GUIDE.md
Migration documentation covering:
- Pre-migration checklist
- Migration strategies
- Service-specific instructions
- Import commands
- Rollback procedures

## Adding a New Service

To add a new service to sol-infra:

1. **Create project structure:**
   ```bash
   mkdir -p projects/new-service/{test,prod}
   ```

2. **Copy configuration from similar service:**
   ```bash
   cp -r projects/sol-email-service/test/* projects/new-service/test/
   cp -r projects/sol-email-service/prod/* projects/new-service/prod/
   ```

3. **Update variables and configurations** in both test and prod

4. **Create terraform.tfvars.example** at project level

5. **Test deployment** in test environment first

6. **Update documentation** to include the new service

## Customizing for Your Needs

### Adding a New Module

1. Create directory: `modules/new-module/`
2. Add `main.tf` with resource definitions
3. Document inputs and outputs
4. Test in a project environment
5. Update this STRUCTURE.md

### Modifying Existing Modules

1. Make changes in `modules/*/main.tf`
2. Update all projects that use the module
3. Test thoroughly in test environments
4. Document breaking changes

### Environment-Specific Customization

Each environment can override:
- Resource sizes and limits
- Lifecycle policies
- IAM permissions
- Environment variables
- Labels and naming

## Best Practices

1. **Keep modules generic** - Don't hardcode service-specific values
2. **Use consistent naming** - Follow established patterns
3. **Document changes** - Update relevant .md files
4. **Test first** - Always validate in test before prod
5. **Version control** - Commit infrastructure changes with code
