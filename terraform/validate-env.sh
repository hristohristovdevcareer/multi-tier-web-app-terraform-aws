#!/bin/bash

# Array of required environment variables
declare -a required_vars=(
    "EC2_INSTANCE_TYPE"
    "EC2_INSTANCE_AMI"
    "EC2_INSTANCE_NAME"
    "CIDR_VPC"
    "CIDR_GATEWAY"
    "CIDR_ROUTE_TABLE"
    "SECURITY_GROUP_NAME"
    "SECURITY_GROUP_DESCRIPTION"
    "ALLOW_HTTP"
    "ALLOW_HTTPS"
    "ALLOW_SSH"
    "PROJECT_NAME"
    "BRANCH_NAME"
    "REGION"
    "TF_PROFILE"
    "VAULT_ADDR"
    "ECS_FRONTEND_LOG_GROUP"
    "ECS_BACKEND_LOG_GROUP"
    "IMAGE_TAG"
    "ECR_IMAGE_TAG"
    "DOMAIN_NAME"
    "CLOUDFLARE_ZONE_ID"
    "CLOUDFLARE_API_TOKEN"
    "VAULT_TOKEN"
    "INTERNAL_SERVICE_NAME"
    "NODE_EXTRA_CA_CERTS"
)

# Function to check if variable is set
check_var() {
    if [ -z "${!1}" ]; then
        echo "❌ $1 is not set"
        return 1
    else
        echo "✅ $1 is set"
        return 0
    fi
}

# Check all required variables
missing_vars=0
echo "Checking environment variables..."
echo "--------------------------------"

for var in "${required_vars[@]}"; do
    if ! check_var "$var"; then
        missing_vars=$((missing_vars + 1))
    fi
done

echo "--------------------------------"
if [ $missing_vars -gt 0 ]; then
    echo "❌ Warning: $missing_vars required environment variable(s) are missing"
else
    echo "✅ All required environment variables are set"
fi