variable "CIDR_VPC" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "AVAILABILITY_ZONES" {
  description = "Availability zones for the VPC"
  type        = list(string)
}