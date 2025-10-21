# Terragrunt Usage Guide

This repository uses **Terragrunt** to keep infrastructure code DRY (Don't Repeat Yourself) across environments.

## Why Terragrunt?

Instead of duplicating Terraform code for each environment (test, prod), Terragrunt allows us to:
- **Write infrastructure code once** in `service-modules/`
- **Configure per-environment** with small `terragrunt.hcl` files
- **Share common settings** via root and environment configs
- **Automatically manage** remote state, providers, and backends

## Structure

```
sol-infra/
├── terragrunt.hcl                    # Root config (common to all)
├── modules/                           # Reusable Terraform modules
├── service-modules/                   # Service-specific Terraform (shared across envs)
│   ├── sol-email-service/
│   │   ├── main.tf                   # Service infrastructure (ONE place!)
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── sol-analytics-service/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── live/                              # Environment configurations
    ├── test/
    │   ├── env.hcl                   # Test environment defaults
    │   ├── sol-email-service/
    │   │   └── terragrunt.hcl        # Just test-specific overrides!
    │   └── sol-analytics-service/
    │       └── terragrunt.hcl
    └── prod/
        ├── env.hcl                   # Prod environment defaults
        ├── sol-email-service/
        │   └── terragrunt.hcl        # Just prod-specific overrides!
        └── sol-analytics-service/
            └── terragrunt.hcl
```

## Installation

Install Terragrunt:

```bash
# macOS
brew install terragrunt

# Linux
wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.54.0/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

# Verify
terragrunt --version
```

You also need Terraform installed (>= 1.0).

## Usage

### Deploy a Single Service

```bash
# Navigate to the service environment
cd live/test/sol-email-service

# Initialize (downloads modules, sets up backend)
terragrunt init

# Plan changes
terragrunt plan

# Apply changes
terragrunt apply

# View outputs
terragrunt output
```

### Deploy All Services in an Environment

From the environment directory:

```bash
cd live/test

# Apply all services in test
terragrunt run-all apply

# Or just plan
terragrunt run-all plan
```

### Deploy Everything

From the root:

```bash
# Apply all environments and services
terragrunt run-all apply --terragrunt-working-dir live

# Be careful with this in production!
```

## Common Commands

| Command | Description |
|---------|-------------|
| `terragrunt init` | Initialize Terraform and download modules |
| `terragrunt plan` | Show execution plan |
| `terragrunt apply` | Apply infrastructure changes |
| `terragrunt destroy` | Destroy infrastructure |
| `terragrunt output` | Show output values |
| `terragrunt run-all <cmd>` | Run command on all subdirectories |
| `terragrunt validate` | Validate Terraform syntax |
| `terragrunt state list` | List resources in state |

## How It Works

### 1. Root Configuration (`terragrunt.hcl`)

The root config:
- Generates provider configuration automatically
- Sets up remote state in GCS
- Defines common inputs

### 2. Environment Configuration (`env.hcl`)

Each environment (test, prod) has an `env.hcl` that defines:
- Environment name
- Default resource limits (memory, instances)
- Lifecycle policies
- Common environment settings

**Example (`live/test/env.hcl`):**
```hcl
locals {
  environment = "test"
  min_instance_count = 0
  max_instance_count = 1
  available_memory   = "256M"
  lifecycle_days     = 7
}
```

### 3. Service Modules (`service-modules/`)

The actual Terraform code lives here. This is shared across ALL environments:

```hcl
# service-modules/sol-email-service/main.tf
module "function" {
  source = "../../modules/gcf2_function"
  name   = var.environment == "prod" ? var.function_name : "${var.function_name}-${var.environment}"
  # ... rest of config uses variables
}
```

### 4. Environment-Specific Config (`live/{env}/{service}/terragrunt.hcl`)

Small config files with only overrides:

```hcl
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

terraform {
  source = "../../../service-modules/sol-email-service"
}

inputs = {
  environment           = include.env.locals.environment
  project_id            = "sol-infra-test"
  available_memory      = include.env.locals.available_memory  # Inherit from env
  max_instance_count    = include.env.locals.max_instance_count
  # ... only environment-specific values
}
```

## Benefits

### Before Terragrunt (Duplicate Code)
```
projects/
├── sol-email-service/
│   ├── test/
│   │   ├── main.tf         (200 lines)
│   │   ├── variables.tf    (100 lines)
│   │   ├── providers.tf    (20 lines)
│   │   └── outputs.tf      (30 lines)
│   └── prod/
│       ├── main.tf         (200 lines) - 95% same as test!
│       ├── variables.tf    (100 lines) - 95% same as test!
│       ├── providers.tf    (20 lines) - identical!
│       └── outputs.tf      (30 lines) - identical!
```

**Total duplication: ~700 lines of code!**

### After Terragrunt (DRY)
```
service-modules/
└── sol-email-service/
    ├── main.tf         (200 lines) - ONE place!
    ├── variables.tf    (100 lines)
    └── outputs.tf      (30 lines)

live/
├── test/
│   └── sol-email-service/
│       └── terragrunt.hcl  (30 lines - just overrides!)
└── prod/
    └── sol-email-service/
        └── terragrunt.hcl  (30 lines - just overrides!)
```

**Total: 390 lines (44% reduction!)**

## Adding a New Environment

To add a new environment (e.g., `staging`):

1. **Create environment config:**
   ```bash
   mkdir -p live/staging
   cp live/test/env.hcl live/staging/env.hcl
   ```

2. **Edit environment settings:**
   ```hcl
   # live/staging/env.hcl
   locals {
     environment = "staging"
     min_instance_count = 0
     max_instance_count = 2
     available_memory   = "512M"
     lifecycle_days     = 14
   }
   ```

3. **Create service configs:**
   ```bash
   mkdir -p live/staging/sol-email-service
   cp live/test/sol-email-service/terragrunt.hcl live/staging/sol-email-service/
   ```

4. **Update project ID and any staging-specific values:**
   ```hcl
   # live/staging/sol-email-service/terragrunt.hcl
   inputs = {
     project_id = "sol-infra-staging"
     # ... rest inherits from env.hcl
   }
   ```

Done! No need to duplicate 700 lines of Terraform code.

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy with Terragrunt

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.5.0'
      
      - name: Setup Terragrunt
        run: |
          wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.54.0/terragrunt_linux_amd64
          chmod +x terragrunt_linux_amd64
          sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
      
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}
      
      - name: Deploy to prod
        run: |
          cd live/prod/sol-email-service
          terragrunt apply -auto-approve
```

## Troubleshooting

### Issue: "Could not find terragrunt.hcl"

**Solution:** Make sure you're in the correct directory. Terragrunt looks for `terragrunt.hcl` in the current directory.

### Issue: "Error: Module not found"

**Solution:** Run `terragrunt init` to download the module source.

### Issue: "Backend configuration changed"

**Solution:** Run `terragrunt init -reconfigure`

### Issue: "No such file: env.hcl"

**Solution:** The `env.hcl` file should be in the environment directory (`live/test/` or `live/prod/`)

## Advanced Features

### Dependencies Between Services

If one service depends on another:

```hcl
# live/prod/service-b/terragrunt.hcl
dependency "service_a" {
  config_path = "../service-a"
}

inputs = {
  service_a_output = dependency.service_a.outputs.some_value
}
```

### Running Commands on Multiple Modules

```bash
# Plan all services in test
cd live/test
terragrunt run-all plan

# Apply only specific services
terragrunt run-all apply --terragrunt-include-dir sol-email-service
```

### Using Environment Variables

```hcl
# In terragrunt.hcl
inputs = {
  mailgun_api_key = get_env("MAILGUN_API_KEY", "")
  project_id      = get_env("TF_VAR_project_id", "default-project")
}
```

## Best Practices

1. **Keep service modules generic** - Use variables for everything environment-specific
2. **Use env.hcl for common settings** - Memory limits, instance counts, etc.
3. **Minimize terragrunt.hcl files** - Only override what's different
4. **Use remote state** - Already configured in root terragrunt.hcl
5. **Test changes in test environment first** - Always!
6. **Use `run-all` with caution** - Easy to deploy everything accidentally

## Comparison: Terraform vs Terragrunt Commands

| Task | Terraform | Terragrunt |
|------|-----------|------------|
| Initialize | `terraform init` | `terragrunt init` |
| Plan | `terraform plan` | `terragrunt plan` |
| Apply | `terraform apply` | `terragrunt apply` |
| Destroy | `terraform destroy` | `terragrunt destroy` |
| Format | `terraform fmt` | `terragrunt hclfmt` |
| Validate | `terraform validate` | `terragrunt validate` |
| All modules | N/A | `terragrunt run-all <cmd>` |

## Migration from Old Structure

If you were using the old `projects/` structure:

1. The Terraform code is now in `service-modules/`
2. Environment configs are in `live/{env}/{service}/terragrunt.hcl`
3. Run `terragrunt init` instead of `terraform init`
4. Everything else works the same!

## Need Help?

- **Terragrunt Docs:** https://terragrunt.gruntwork.io/
- **Examples:** Check the `live/` directory for working examples
- **Issues:** Review error messages carefully - Terragrunt shows which file has the issue
