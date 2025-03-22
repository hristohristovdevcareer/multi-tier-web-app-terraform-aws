variable "PUBLIC_SUBNET_IDS" {
  description = "Public Subnet IDs"
  type        = list(string)
}

variable "PRIVATE_SUBNET_IDS" {
  description = "Private Subnet IDs"
  type        = list(string)
}

variable "VPC_ID" {
  description = "VPC ID"
  type        = string
}

variable "ALB_SECURITY_GROUP_ID" {
  description = "ALB Security Group ID"
  type        = string
}

variable "DOMAIN_NAME" {
  description = "Domain name"
  type        = string
}

variable "CLOUDFLARE_ZONE_ID" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "CLOUDFLARE_API_TOKEN" {
  description = "Cloudflare API token"
  type        = string
}

variable "BACKEND_ALB_SECURITY_GROUP_ID" {
  description = "Backend Security Group ID"
  type        = string
}

variable "INTERNAL_SERVICE_NAME" {
  description = "Internal service name"
  type        = string
  default     = "backend.internal.service"
}
