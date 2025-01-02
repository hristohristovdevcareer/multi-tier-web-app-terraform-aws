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