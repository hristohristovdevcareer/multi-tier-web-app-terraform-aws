variable "FRONTEND_ECR_REPO" {
  description = "ECR Repository"
  type        = string
}

variable "BACKEND_ECR_REPO" {
  description = "ECR Repository"
  type        = string
}

variable "FRONTEND_TARGET_GROUP_ARN" {
  description = "Target Group ARN"
  type        = string
}

variable "REGION" {
  description = "AWS Region"
  type        = string
}

variable "FRONTEND_ECS_LOG_GROUP" {
  description = "ECS Log Group"
  type        = string
}

variable "BACKEND_ECS_LOG_GROUP" {
  description = "ECS Log Group"
  type        = string
}

variable "ECS_TASK_ROLE_ARN" {
  description = "ECS Task Role ARN"
  type        = string
}

variable "ECS_TASK_EXECUTION_ROLE_ARN" {
  description = "ECS Task Execution Role ARN"
  type        = string
}

variable "DB_HOST" {
  description = "DB Host"
  type        = string
}

variable "DB_NAME" {
  description = "DB Name"
  type        = string
}

variable "DB_USER" {
  description = "DB User"
  type        = string
}

variable "DB_PASSWORD" {
  description = "DB Password"
  type        = string
}

variable "SERVER_URL" {
  description = "Server URL"
  type        = string
}

variable "PROJECT_NAME" {
  description = "Project Name"
  type        = string
}

variable "IMAGE_TAG" {
  description = "Image Tag"
  type        = string
}

variable "PRIVATE_SUBNET_IDS" {
  description = "Private Subnet IDs"
  type        = list(string)
}

variable "PUBLIC_SUBNET_IDS" {
  description = "Public Subnet IDs"
  type        = list(string)
}

variable "EC2_INSTANCE_TYPE" {
  description = "AWS EC2 instance type"
  type        = string
}

variable "EC2_INSTANCE_AMI" {
  description = "AWS EC2 instance ami"
  type        = string
}

variable "IAM_ROLE_DEPENDENCY_FRONTEND_ECS" {
  description = "IAM Role Dependency for Frontend ECS"
  type        = list(any)
}

variable "IAM_ROLE_DEPENDENCY_BACKEND_ECS" {
  description = "IAM Role Dependency for Backend ECS"
  type        = list(any)
}


variable "FRONTEND_ECS_SECURITY_GROUP_ID" {
  description = "Frontend ECS Security Group ID"
  type        = string
}

variable "BACKEND_ECS_SECURITY_GROUP_ID" {
  description = "Backend ECS Security Group ID"
  type        = string
}

variable "EC2_KEY_PAIR_NAME" {
  description = "EC2 Key Pair Name"
  type        = string
}

variable "EC2_INSTANCE_PROFILE_NAME" {
  description = "EC2 Instance Profile Name"
  type        = string
}

variable "AVAILABILITY_ZONES" {
  description = "Availability Zones"
  type        = list(string)
}

