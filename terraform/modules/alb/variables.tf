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
