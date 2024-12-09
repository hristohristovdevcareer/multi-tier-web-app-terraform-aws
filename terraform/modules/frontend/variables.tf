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

variable "EC2_KEY" {
  description = "AWS EC2 key"
  type        = string
  sensitive   = true
}

variable "EC2_IAM_PROFILE_NAME" {
  description = "AWS EC2 IAM profile name"
  type        = string
}

variable "ECS_CLUSTER" {
  description = "AWS ECS cluster name"
  type        = string
}

variable "GITLAB_PRIVATE_KEY" {
  description = "Gitlab private key"
  type        = string
  sensitive   = true
}

variable "GITLAB_PUBLIC_KEY" {
  description = "Gitlab public key"
  type        = string
  sensitive   = true
}

variable "REGION" {
  description = "AWS region"
  type        = string
}

variable "FE_ECR_REPO" {
  description = "AWS ECR repository for the frontend"
  type        = string
}

variable "FE_SECURITY_GROUP" {
  description = "AWS security group for the frontend"
  type        = string
}

variable "EC2_IMAGE_ID" {
  description = "AWS EC2 image id"
  type        = string
}
