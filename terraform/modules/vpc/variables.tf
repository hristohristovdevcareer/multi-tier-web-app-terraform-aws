variable "CIDR_VPC" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "AVAILABILITY_ZONES" {
  description = "Availability zones for the VPC"
  type        = list(string)
}

variable "EC2_INSTANCE_AMI" {
  description = "AMI for the NAT instance"
  type        = string
}

variable "EC2_INSTANCE_TYPE" {
  description = "Type for the NAT instance"
  type        = string
}

variable "NAT_SG" {
  description = "Security group for the NAT instnace"
  type        = string
}

variable "NAT_KEY_PAIR_NAME" {
  description = "Key pair name for the NAT instance"
  type        = string
}