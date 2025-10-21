# Sol Infrastructure Makefile
# Provides convenient commands for common operations

.PHONY: help init plan apply destroy fmt validate clean

# Default target
help:
	@echo "Sol Infrastructure Management"
	@echo ""
	@echo "Usage:"
	@echo "  make init SERVICE=sol-email-service ENV=test    - Initialize Terraform"
	@echo "  make plan SERVICE=sol-email-service ENV=test    - Show execution plan"
	@echo "  make apply SERVICE=sol-email-service ENV=test   - Apply configuration"
	@echo "  make destroy SERVICE=sol-email-service ENV=test - Destroy infrastructure"
	@echo "  make fmt                                         - Format all .tf files"
	@echo "  make validate SERVICE=sol-email-service ENV=test - Validate configuration"
	@echo "  make clean                                       - Remove .terraform directories"
	@echo ""
	@echo "Examples:"
	@echo "  make init SERVICE=sol-email-service ENV=prod"
	@echo "  make plan SERVICE=sol-analytics-service ENV=test"
	@echo ""

# Validate required variables
check-vars:
ifndef SERVICE
	$(error SERVICE is not set. Use: make <target> SERVICE=sol-email-service ENV=test)
endif
ifndef ENV
	$(error ENV is not set. Use: make <target> SERVICE=sol-email-service ENV=test)
endif

# Initialize Terraform
init: check-vars
	cd projects/$(SERVICE)/$(ENV) && terraform init

# Show execution plan
plan: check-vars
	cd projects/$(SERVICE)/$(ENV) && terraform plan

# Apply configuration
apply: check-vars
	cd projects/$(SERVICE)/$(ENV) && terraform apply

# Destroy infrastructure
destroy: check-vars
	@echo "WARNING: This will destroy all infrastructure for $(SERVICE) $(ENV)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd projects/$(SERVICE)/$(ENV) && terraform destroy; \
	fi

# Format all Terraform files
fmt:
	terraform fmt -recursive .

# Validate configuration
validate: check-vars
	cd projects/$(SERVICE)/$(ENV) && terraform validate

# Clean up .terraform directories
clean:
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "Cleaned up Terraform cache directories"

# Show outputs
output: check-vars
	cd projects/$(SERVICE)/$(ENV) && terraform output

# Refresh state
refresh: check-vars
	cd projects/$(SERVICE)/$(ENV) && terraform refresh

# List resources
list: check-vars
	cd projects/$(SERVICE)/$(ENV) && terraform state list

# Show specific resource
show: check-vars
ifndef RESOURCE
	$(error RESOURCE is not set. Use: make show SERVICE=... ENV=... RESOURCE=module.function.google_cloudfunctions2_function.this)
endif
	cd projects/$(SERVICE)/$(ENV) && terraform state show $(RESOURCE)
