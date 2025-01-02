terraform {
  required_version = "~>1.8"

  # backend "s3" {
  #   bucket         = "multi-tier-aws-app-terraform-state-bucket"
  #   key            = "terraform.tfstate"
  #   region         = "eu-west-2"
  #   dynamodb_table = "multi-tier-aws-app-terraform-state-lock"
  #   encrypt        = true
  # }

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

module "vault" {
  source = "./modules/vault"

  DB_USERNAME        = data.vault_generic_secret.db_credentials.data["username"]
  DB_PASSWORD        = data.vault_generic_secret.db_credentials.data["password"]
  GITLAB_PRIVATE_KEY = data.vault_generic_secret.gitlab_private_key.data["gitlab_private_key"]
  GITLAB_PUBLIC_KEY  = data.vault_generic_secret.gitlab_public_key.data["gitlab_public_key"]
  EC2_SSH_PUBLIC_KEY = data.vault_generic_secret.ec2_ssh_public_key.data["ec2_ssh_public_key"]
}

# Key Pair for the EC2 instance
resource "aws_key_pair" "ec2" {
  key_name   = "ec-2-key"
  public_key = data.vault_generic_secret.ec2_ssh_public_key.data["ec2_ssh_public_key"]
}

module "tf_state" {
  source = "./modules/tf-state"

  TF_STATE_BUCKET_NAME = local.BUCKET_NAME
  TABLE_NAME           = local.TABLE_NAME
}

module "vpc" {
  source = "./modules/vpc"

  CIDR_VPC           = var.CIDR_VPC
  AVAILABILITY_ZONES = ["eu-west-2a", "eu-west-2b"]
  EC2_INSTANCE_AMI   = var.EC2_INSTANCE_AMI
  EC2_INSTANCE_TYPE  = var.EC2_INSTANCE_TYPE
  NAT_SG             = module.security_groups.nat_sg
}

module "security_groups" {
  source = "./modules/security_groups"

  VPC       = module.vpc.vpc_id
  ALLOW_SSH = true
  CIDR_VPC  = var.CIDR_VPC
}


module "alb" {
  source = "./modules/alb"

  VPC_ID                = module.vpc.vpc_id
  PUBLIC_SUBNET_IDS     = module.vpc.public_subnet_ids
  PRIVATE_SUBNET_IDS    = module.vpc.private_subnet_ids
  ALB_SECURITY_GROUP_ID = module.security_groups.alb_security_group
}


module "rds" {
  source = "./modules/rds"

  PRIVATE_SUBNET_IDS    = module.vpc.private_subnet_ids
  RDS_SECURITY_GROUP_ID = module.security_groups.rds_security_group
  DB_USERNAME           = data.vault_generic_secret.db_credentials.data["username"]
  DB_PASSWORD           = data.vault_generic_secret.db_credentials.data["password"]
}

module "ecr" {
  source = "./modules/ecr"

  REGION       = var.REGION
  PROJECT_NAME = var.PROJECT_NAME
  SERVICES     = var.SERVICES
  DB_HOST      = module.rds.db_instance_endpoint
  DB_NAME      = module.rds.db_instance_name
  DB_USER      = module.rds.db_instance_username
  DB_PASSWORD  = module.rds.db_instance_password
  IMAGE_TAG    = var.ECR_IMAGE_TAG
}

module "iam" {
  source = "./modules/iam"

  REGION       = var.REGION
  PROJECT_NAME = var.PROJECT_NAME

}

module "ecs" {
  source = "./modules/ecs"

  FRONTEND_ECR_REPO                = module.ecr.web_app_repository_url
  BACKEND_ECR_REPO                 = module.ecr.server_repository_url
  FRONTEND_TARGET_GROUP_ARN        = module.alb.frontend_target_group_arn
  REGION                           = var.REGION
  FRONTEND_ECS_LOG_GROUP           = var.ECS_FRONTEND_LOG_GROUP
  BACKEND_ECS_LOG_GROUP            = var.ECS_BACKEND_LOG_GROUP
  ECS_TASK_ROLE_ARN                = module.iam.ecs_task_role_arn
  ECS_TASK_EXECUTION_ROLE_ARN      = module.iam.ecs_task_execution_role_arn
  DB_HOST                          = module.rds.db_instance_endpoint
  DB_NAME                          = module.rds.db_instance_name
  DB_USER                          = module.rds.db_instance_username
  DB_PASSWORD                      = module.rds.db_instance_password
  SERVER_URL                       = "localhost"
  PROJECT_NAME                     = var.PROJECT_NAME
  IMAGE_TAG                        = var.IMAGE_TAG
  PUBLIC_SUBNET_IDS                = module.vpc.public_subnet_ids
  PRIVATE_SUBNET_IDS               = module.vpc.private_subnet_ids
  EC2_INSTANCE_TYPE                = var.EC2_INSTANCE_TYPE
  EC2_INSTANCE_AMI                 = var.EC2_INSTANCE_AMI
  IAM_ROLE_DEPENDENCY_FRONTEND_ECS = [module.iam.ecs_task_execution_role, module.iam.ecs_task_role]
  IAM_ROLE_DEPENDENCY_BACKEND_ECS  = [module.iam.ecs_task_execution_role, module.iam.ecs_task_role]
  FRONTEND_ECS_SECURITY_GROUP_ID   = module.security_groups.frontend_ecs_security_group
  BACKEND_ECS_SECURITY_GROUP_ID    = module.security_groups.backend_ecs_security_group
  EC2_KEY_PAIR_NAME                = aws_key_pair.ec2.key_name
  EC2_INSTANCE_PROFILE_NAME        = module.iam.ec2_instance_profile_name
}
  