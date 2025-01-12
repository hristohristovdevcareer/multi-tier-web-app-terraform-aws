variable "VPC" {
  description = "VPC ID"
  type        = string
}

variable "ALLOW_SSH" {
  description = "Allow SSH traffic"
  type        = bool
}

variable "CIDR_VPC" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "PRIVATE_SUBNET_CIDR_BLOCKS" {
  description = "Private Subnet CIDR Blocks"
  type        = list(string)
}
