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

# variable "GITLAB_PRIVATE_KEY" {
#   description = "Private key to connect to gitlab through ssh"
#   type        = string
#   sensitive   = true
# }

# variable "GITLAB_PUBLIC_KEY" {
#   description = "Private key to connect to gitlab through ssh"
#   type        = string
#   sensitive   = true
# }

# variable "SSH_EC2" {
#   description = "SSH key-pair"
#   type        = string
#   sensitive   = true
# }

variable "REGION" {
  description = "Region to host the infrastructure"
  type        = string
}

# Docker Compose and Dockerfile paths for each service
variable "SERVICES" {
  description = "Configuration for Docker build and push"
  type = map(object({
    docker_compose = string
    dockerfile     = string
    project_name   = string
  }))
}

variable "TF_PROFILE" {
  description = "AWS profile"
  type        = string
}

variable "VAULT_ADDR" {
  description = "Vault address"
  type        = string
}

variable "ECS_FRONTEND_LOG_GROUP" {
  description = "ECS Log Group"
  type        = string
}

variable "ECS_BACKEND_LOG_GROUP" {
  description = "ECS Log Group"
  type        = string
}

variable "IMAGE_TAG" {
  description = "Image tag"
  type        = string
}

variable "ECR_IMAGE_TAG" {
  description = "ECR Image tag"
  type        = string
}
