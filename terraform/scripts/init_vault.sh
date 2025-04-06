#!/bin/bash

# Start Vault server in dev mode in background and save initial output to a file
vault server -dev > vault_output.txt 2>&1 &

# Wait for Vault to write the token (max 10 seconds)
max_attempts=10
attempt=1
while [ $attempt -le $max_attempts ]; do
    if grep -q "Root Token:" vault_output.txt; then
        break
    fi
    sleep 1
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "Error: Vault failed to start and provide a token within $max_attempts seconds"
    exit 1
fi

# Extract the root token from the file
ROOT_TOKEN=$(cat vault_output.txt | grep -o 'Root Token: [a-zA-Z0-9.]*' | cut -d' ' -f3)

# Export the Vault address and token directly to environment
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN="$ROOT_TOKEN"
export TF_VAR_VAULT_TOKEN="$ROOT_TOKEN"
# Clean up the temporary file
rm vault_output.txt

# Create the initial secrets from vault.json
VAULT_SECRETS=$(cat vault.json)

# Create secrets in Vault
vault kv put secret/gitlab_keys \
    gitlab_private_key="$(echo $VAULT_SECRETS | jq -r '.GITLAB_PRIVATE_KEY')" \
    gitlab_public_key="$(echo $VAULT_SECRETS | jq -r '.GITLAB_PUBLIC_KEY')"

vault kv put secret/ec2_ssh \
    ec2_ssh_public_key="$(echo $VAULT_SECRETS | jq -r '.SSH_EC2_KEY')" \
    nat_ssh_private_key="$(echo $VAULT_SECRETS | jq -r '.SSH_EC2_NAT_PVT')"

vault kv put secret/db_credentials \
    username="$(echo $VAULT_SECRETS | jq -r '.username')" \
    password="$(echo $VAULT_SECRETS | jq -r '.password')"

vault kv put secret/cloudflare \
    cloudflare_api_token="$(echo $VAULT_SECRETS | jq -r '.CLOUDFLARE_API_TOKEN')" \
    cloudflare_zone_id="$(echo $VAULT_SECRETS | jq -r '.CLOUDFLARE_ZONE_ID')"

# Display the token for the user
echo "Vault Root Token: $ROOT_TOKEN"
echo "Vault Address: $VAULT_ADDR"

# Run your environment variable setup script
source set-env-vars.sh

# Add check for required environment variables
if [ -z "$TF_VAR_CLOUDFLARE_API_TOKEN" ] || [ -z "$TF_VAR_CLOUDFLARE_ZONE_ID" ]; then
    echo "Error: Cloudflare credentials not set in environment"
    exit 1
fi

# You might want to add checks for other critical variables too
if [ -z "$VAULT_TOKEN" ] || [ -z "$VAULT_ADDR" ]; then
    echo "Error: Vault credentials not set in environment"
    exit 1
fi