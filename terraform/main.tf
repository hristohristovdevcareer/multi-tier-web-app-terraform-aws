terraform {
  required_version = "1.9.8"
  required_providers {
    vault = {
      source = "hashicorp/vault"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Key Pair for the EC2 instance
resource "aws_key_pair" "ec2" {
  key_name   = "ec-2-key"
  public_key = data.vault_generic_secret.ec2_ssh_public_key.data["ec2_ssh_public_key"]
}

module "vpc" {
  source = "./modules/vpc"

  CIDR_VPC           = var.CIDR_VPC
  AVAILABILITY_ZONES = ["eu-west-2a"]
}

module "security_groups" {
  source = "./modules/security_groups"

  VPC       = module.vpc.vpc_id
  ALLOW_SSH = true
}

module "frontend" {
  source = "./modules/frontend"

  EC2_INSTANCE_TYPE    = var.EC2_INSTANCE_TYPE
  EC2_INSTANCE_NAME    = var.EC2_INSTANCE_NAME
  EC2_KEY              = aws_key_pair.ec2.key_name
  EC2_INSTANCE_AMI     = var.EC2_INSTANCE_AMI
  EC2_IAM_PROFILE_NAME = module.iam.ec2_ecr_instance_profile_name
  ECS_CLUSTER          = module.ecs.ecs_cluster_id
  GITLAB_PRIVATE_KEY   = data.vault_generic_secret.gitlab_private_key.data["gitlab_private_key"]
  GITLAB_PUBLIC_KEY    = data.vault_generic_secret.gitlab_public_key.data["gitlab_public_key"]
  REGION               = var.REGION
  FE_ECR_REPO          = module.ecr.web_app_repository_url
  FE_SECURITY_GROUP    = module.security_groups.frontend_ecs_security_group
  EC2_IMAGE_ID         = var.EC2_INSTANCE_AMI
}

module "backend" {
  source = "./modules/backend"

  EC2_INSTANCE_TYPE    = var.EC2_INSTANCE_TYPE
  EC2_INSTANCE_NAME    = var.EC2_INSTANCE_NAME
  EC2_KEY              = aws_key_pair.ec2.key_name
  EC2_INSTANCE_AMI     = var.EC2_INSTANCE_AMI
  EC2_IAM_PROFILE_NAME = module.iam.ec2_ecr_instance_profile_name
  ECS_CLUSTER          = module.ecs.ecs_cluster_id
  GITLAB_PRIVATE_KEY   = data.vault_generic_secret.gitlab_private_key.data["gitlab_private_key"]
  GITLAB_PUBLIC_KEY    = data.vault_generic_secret.gitlab_public_key.data["gitlab_public_key"]
  REGION               = var.REGION
  BE_ECR_REPO          = module.ecr.server_repository_url
  BE_SECURITY_GROUP    = module.security_groups.backend_ecs_security_group
  EC2_IMAGE_ID         = var.EC2_INSTANCE_AMI
}



module "iam" {
  source = "./modules/iam"

  REGION       = var.REGION
  PROJECT_NAME = var.PROJECT_NAME
}

module "ecr" {
  source = "./modules/ecr"

  REGION       = var.REGION
  PROJECT_NAME = var.PROJECT_NAME
  SERVICES     = var.SERVICES
}

module "ecs" {
  source = "./modules/ecs"

  FRONTEND_ECR_REPO         = module.ecr.web_app_repository_url
  BACKEND_ECR_REPO          = module.ecr.server_repository_url
  CLUSTER_ID                = module.ecs.ecs_cluster_id
  FRONTEND_TARGET_GROUP_ARN = module.alb.frontend_target_group_arn
  BACKEND_TARGET_GROUP_ARN  = module.alb.backend_target_group_arn
}

module "alb" {
  source = "./modules/alb"

  FRONTEND_LAUNCH_TEMPLATE_ID = module.frontend.frontend_launch_template_id
  BACKEND_LAUNCH_TEMPLATE_ID  = module.backend.backend_launch_template_id
  PUBLIC_SUBNET_IDS           = module.vpc.public_subnet_ids
  PRIVATE_SUBNET_IDS          = module.vpc.private_subnet_ids
  VPC_ID                      = module.vpc.vpc_id
  ALB_SECURITY_GROUP_ID       = module.security_groups.alb_security_group
}

module "tf_state" {
  source = "./modules/tf-state"

  TF_STATE_BUCKET_NAME = local.BUCKET_NAME
  TABLE_NAME           = local.TABLE_NAME
}
