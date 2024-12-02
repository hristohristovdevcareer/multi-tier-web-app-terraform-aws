variable "EC2_INSTANCE_NAME" {
  description = "Value of the name tag for the EC2 instance"
  type        = string
}

variable "EC2_INSTANCE_TYPE" {
  description = "AWS EC2 instance type"
  type        = string
}

variable "EC2_INSTANCE_AMI" {
  description = "AWS EC2 instance ami"
  type        = string
}

variable "CIDR_VPC" {
  description = "VPC CIDR IP"
  type        = string
}

variable "CIDR_SUBNET" {
  description = "Subnet CIDR IP"
  type        = string
}

variable "CIDR_GATEWAY" {
  description = "Gateway CIDR IP"
  type        = string
}

variable "CIDR_ROUTE_TABLE" {
  description = "Route table CIDR"
  type        = string
}

variable "SECURITY_GROUP_NAME" {
  description = "Security group name"
  type        = string
}

variable "SECURITY_GROUP_DESCRIPTION" {
  description = "Security group description"
  type        = string
}

variable "ALLOW_HTTP" {
  description = "Enable HTTP access (port 80)"
  type        = bool
  default     = false
}

variable "ALLOW_HTTPS" {
  description = "Enable HTTPS access (port 443)"
  type        = bool
  default     = false
}

variable "ALLOW_SSH" {
  description = "Enable SSH access (port 22)"
  type        = bool
  default     = false
}

variable "PROJECT_NAME" {
  description = "The name of the project"
  type        = string
}

variable "BRANCH_NAME" {
  description = "Project branch from which the files for the server will be fetched"
  type        = string
}

variable "REPO_URL" {
  description = "Project repo url"
  type        = string
}

variable "GITLAB_PRIVATE_KEY" {
  description = "Private key to connect to gitlab through ssh"
  type        = string
  sensitive   = true
}

variable "GITLAB_PUBLIC_KEY" {
  description = "Private key to connect to gitlab through ssh"
  type        = string
  sensitive   = true
}

variable "SSH_EC2" {
  description = "SSH key-pair"
  type        = string
  sensitive   = true
}

variable "REGION" {
  description = "Region to host the infrastructure"
  type        = string
}

variable "services" {
  description = "Configuration for Docker build and push"
  type = map(object({
    docker_compose = string
    dockerfile     = string
    project_name   = string
    ecr_repo_url   = string
  }))
}

variable "CIDR_SUBNET_PUBLIC" {
  description = "Public Subnet CIDR IP"
  type        = string
}

variable "CIDR_SUBNET_PRIVATE" {
  description = "Private Subnet CIDR IP"
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
