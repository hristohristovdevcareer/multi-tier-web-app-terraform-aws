#!/bin/bash

# Make all scripts executable
chmod -x ./scripts/*

# Source environment variables
source ./scripts/set-env-vars.sh

# Initialize Vault if needed
source ./scripts/init_vault.sh

# Validate environment variables
source ./scripts/validate-env.sh

# Run Terraform commands
echo "Environment setup complete. You can now run Terraform commands."