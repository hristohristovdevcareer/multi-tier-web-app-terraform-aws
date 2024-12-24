variable "PRIVATE_SUBNET_IDS" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "RDS_SECURITY_GROUP_ID" {
  description = "Security group ID for RDS"
  type        = string
}

variable "DB_USERNAME" {
  description = "Database master username"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.DB_USERNAME) >= 1 && length(var.DB_USERNAME) <= 16 && var.DB_USERNAME == regex("^[a-zA-Z][a-zA-Z0-9]*$", var.DB_USERNAME)
    error_message = "The DB_USERNAME must be 1-16 alphanumeric characters, starting with a letter, and cannot contain special characters."
  }
}

variable "DB_PASSWORD" {
  description = "Database master password"
  type        = string
  sensitive   = true
}