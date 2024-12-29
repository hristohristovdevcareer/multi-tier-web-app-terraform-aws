variable "FRONTEND_ECR_REPO" {
  description = "ECR Repository"
  type        = string
}

variable "BACKEND_ECR_REPO" {
  description = "ECR Repository"
  type        = string
}

variable "CLUSTER_ID" {
  description = "ECS Cluster ID"
  type        = string
}

variable "FRONTEND_TARGET_GROUP_ARN" {
  description = "Target Group ARN"
  type        = string
}

variable "BACKEND_TARGET_GROUP_ARN" {
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

