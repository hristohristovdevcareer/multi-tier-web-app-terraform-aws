# Backup DB credentials
resource "vault_generic_secret" "db_credentials_backup" {
  path = "secret/db_credentials_backup"

  data_json = jsonencode({
    username = var.DB_USERNAME
    password = var.DB_PASSWORD
  })
}

# Backup GitLab keys
resource "vault_generic_secret" "gitlab_keys_backup" {
  path = "secret/gitlab_keys_backup"

  data_json = jsonencode({
    gitlab_private_key = var.GITLAB_PRIVATE_KEY
    gitlab_public_key  = var.GITLAB_PUBLIC_KEY
  })
}

# Backup EC2 SSH keys
resource "vault_generic_secret" "ec2_ssh_backup" {
  path = "secret/ec2_ssh_backup"

  data_json = jsonencode({
    ec2_ssh_public_key = var.EC2_SSH_PUBLIC_KEY
  })
}