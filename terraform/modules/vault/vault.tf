locals {
  vault_secrets = jsondecode(file("${path.module}/../../vault.json"))
}

# Backup DB credentials
resource "vault_generic_secret" "db_credentials" {
  path = "secret/db_credentials"

  data_json = jsonencode({
    username = local.vault_secrets.username
    password = local.vault_secrets.password
  })
}

# Backup GitLab keys
resource "vault_generic_secret" "gitlab_keys" {
  path = "secret/gitlab_keys"

  data_json = jsonencode({
    gitlab_private_key = local.vault_secrets.GITLAB_PRIVATE_KEY
    gitlab_public_key  = local.vault_secrets.GITLAB_PUBLIC_KEY
  })
}

# Backup EC2 SSH keys
resource "vault_generic_secret" "ec2_ssh" {
  path = "secret/ec2_ssh"

  data_json = jsonencode({
    ec2_ssh_public_key  = local.vault_secrets.SSH_EC2_KEY
    nat_ssh_private_key = local.vault_secrets.SSH_EC2_NAT_PVT
  })
}

resource "vault_generic_secret" "cloudflare" {
  path = "secret/cloudflare"

  data_json = jsonencode({
    cloudflare_api_token = local.vault_secrets.CLOUDFLARE_API_TOKEN
    cloudflare_zone_id   = local.vault_secrets.CLOUDFLARE_ZONE_ID
  })
}