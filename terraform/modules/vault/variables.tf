variable "DB_USERNAME" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "DB_PASSWORD" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "GITLAB_PRIVATE_KEY" {
  description = "GitLab private key"
  type        = string
  sensitive   = true
}

variable "GITLAB_PUBLIC_KEY" {
  description = "GitLab public key"
  type        = string
  sensitive   = true
}

variable "EC2_SSH_PUBLIC_KEY" {
  description = "EC2 SSH public key"
  type        = string
  sensitive   = true
}
