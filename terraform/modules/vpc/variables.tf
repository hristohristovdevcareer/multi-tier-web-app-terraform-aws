variable "CIDR_VPC" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "NAT_INSTANCE_AMI" {
  description = "AMI for the NAT instance"
  type        = string
}

variable "NAT_INSTANCE_TYPE" {
  description = "Instance type for the NAT instance"
  type        = string
}

variable "AVAILABILITY_ZONES" {
  description = "Availability zones for the VPC"
  type        = list(string)
}