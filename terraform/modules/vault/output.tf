output "db_credentials_backup" {
  description = "Database credentials backup"
  value       = vault_generic_secret.db_credentials_backup
}

output "gitlab_keys_backup" {
  description = "GitLab keys backup"
  value       = vault_generic_secret.gitlab_keys_backup
}

output "ec2_ssh_backup" {
  description = "EC2 SSH keys backup"
  value       = vault_generic_secret.ec2_ssh_backup
}
