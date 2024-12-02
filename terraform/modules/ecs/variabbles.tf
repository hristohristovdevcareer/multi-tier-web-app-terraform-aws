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
