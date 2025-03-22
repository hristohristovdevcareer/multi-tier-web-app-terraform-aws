output "db_credentials" {
  description = "Database credentials"
  value       = vault_generic_secret.db_credentials
}

output "gitlab_keys" {
  description = "GitLab keys"
  value       = vault_generic_secret.gitlab_keys
}

output "ec2_ssh" {
  description = "EC2 SSH keys"
  value       = vault_generic_secret.ec2_ssh
}

output "cloudflare" {
  description = "Cloudflare keys"
  value       = vault_generic_secret.cloudflare
}
