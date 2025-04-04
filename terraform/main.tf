terraform {
  required_version = "~>1.8"
  backend "s3" {
    bucket         = "multi-tier-aws-app-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    acl            = "bucket-owner-full-control"
    use_lockfile   = true
  }


  required_providers {
    vault = {
      source = "hashicorp/vault"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

module "vault" {
  source = "./modules/vault"
}

# Key Pair for the EC2 instance
resource "aws_key_pair" "ec2" {
  key_name   = "ec-2-key"
  public_key = data.vault_generic_secret.ec2_ssh_public_key.data["ec2_ssh_public_key"]
  depends_on = [module.vault]
}

module "vpc" {
  source = "./modules/vpc"

  CIDR_VPC           = var.CIDR_VPC
  AVAILABILITY_ZONES = var.AVAILABILITY_ZONES
  EC2_INSTANCE_AMI   = var.EC2_INSTANCE_AMI
  EC2_INSTANCE_TYPE  = var.EC2_INSTANCE_TYPE
  NAT_SG             = module.security_groups.nat_sg
  NAT_KEY_PAIR_NAME  = data.vault_generic_secret.nat_ssh_private_key.data["nat_ssh_private_key"]
  depends_on         = [module.vault]
}

module "security_groups" {
  source = "./modules/security_groups"

  VPC                        = module.vpc.vpc_id
  ALLOW_SSH                  = true
  CIDR_VPC                   = var.CIDR_VPC
  PRIVATE_SUBNET_CIDR_BLOCKS = module.vpc.private_subnet_cidr_blocks
}


module "alb" {
  source = "./modules/alb"

  VPC_ID                        = module.vpc.vpc_id
  PUBLIC_SUBNET_IDS             = module.vpc.public_subnet_ids
  PRIVATE_SUBNET_IDS            = module.vpc.private_subnet_ids
  ALB_SECURITY_GROUP_ID         = module.security_groups.alb_security_group
  DOMAIN_NAME                   = var.DOMAIN_NAME
  CLOUDFLARE_ZONE_ID            = var.CLOUDFLARE_ZONE_ID
  CLOUDFLARE_API_TOKEN          = var.CLOUDFLARE_API_TOKEN
  BACKEND_ALB_SECURITY_GROUP_ID = module.security_groups.backend_alb_security_group
  INTERNAL_SERVICE_NAME         = var.INTERNAL_SERVICE_NAME
  depends_on                    = [module.vault]
}

# module "rds" {
#   source = "./modules/rds"

#   PRIVATE_SUBNET_IDS    = module.vpc.private_subnet_ids
#   RDS_SECURITY_GROUP_ID = module.security_groups.rds_security_group
#   DB_USERNAME           = data.vault_generic_secret.db_credentials.data["username"]
#   DB_PASSWORD           = data.vault_generic_secret.db_credentials.data["password"]
# }

module "ecr" {
  source = "./modules/ecr"

  AWS_REGION   = var.REGION
  PROJECT_NAME = var.PROJECT_NAME
  SERVICES     = var.SERVICES
  # DB_HOST      = module.rds.db_instance_endpoint 
  # DB_NAME      = module.rds.db_instance_name
  # DB_USER      = module.rds.db_instance_username
  # DB_PASSWORD  = module.rds.db_instance_password
  DB_HOST                = "localhost"
  DB_NAME                = "postgres"
  DB_USER                = "postgres"
  DB_PASSWORD            = "postgres"
  IMAGE_TAG              = var.ECR_IMAGE_TAG
  NEXT_PUBLIC_SERVER_URL = "https://${module.alb.backend_alb_dns_name}"
  NODE_EXTRA_CA_CERTS    = "/app/certs/internal-ca.crt"
  CLIENT_URL             = "https://${module.alb.frontend_alb_dns_name}"
}

module "iam" {
  source = "./modules/iam"

  REGION       = var.REGION
  PROJECT_NAME = var.PROJECT_NAME

}

# Store the internal certificate in SSM Parameter Store
resource "aws_ssm_parameter" "internal_certificate" {
  name        = "/${var.PROJECT_NAME}/internal-certificate"
  description = "Internal self-signed certificate for backend services"
  type        = "SecureString"
  value       = module.alb.internal_certificate_pem

  tags = {
    Name        = "${var.PROJECT_NAME}-internal-certificate"
    Environment = "production"
  }
}

# Store the backend ALB DNS name in SSM Parameter Store
resource "aws_ssm_parameter" "backend_alb_dns" {
  name        = "/${var.PROJECT_NAME}/backend-alb-dns"
  description = "Backend ALB DNS name for frontend to connect to"
  type        = "String"
  value       = "https://${module.alb.backend_alb_dns_name}"

  tags = {
    Name        = "${var.PROJECT_NAME}-backend-alb-dns"
    Environment = "production"
  }
}

module "ecs" {
  source = "./modules/ecs"

  FRONTEND_ECR_REPO           = module.ecr.web_app_repository_url
  BACKEND_ECR_REPO            = module.ecr.server_repository_url
  FRONTEND_TARGET_GROUP_ARN   = module.alb.frontend_target_group_arn
  BACKEND_TARGET_GROUP_ARN    = module.alb.backend_target_group_arn
  REGION                      = var.REGION
  FRONTEND_ECS_LOG_GROUP      = var.ECS_FRONTEND_LOG_GROUP
  BACKEND_ECS_LOG_GROUP       = var.ECS_BACKEND_LOG_GROUP
  ECS_TASK_ROLE_ARN           = module.iam.ecs_task_role_arn
  ECS_TASK_EXECUTION_ROLE_ARN = module.iam.ecs_task_execution_role_arn
  # DB_HOST                          = module.rds.db_instance_endpoint
  # DB_NAME                          = module.rds.db_instance_name
  # DB_USER                          = module.rds.db_instance_username
  # DB_PASSWORD                      = module.rds.db_instance_password
  DB_HOST                          = "localhost"
  DB_NAME                          = "postgres"
  DB_USER                          = "postgres"
  DB_PASSWORD                      = "postgres"
  PROJECT_NAME                     = var.PROJECT_NAME
  IMAGE_TAG                        = var.IMAGE_TAG
  PUBLIC_SUBNET_IDS                = module.vpc.public_subnet_ids
  PRIVATE_SUBNET_IDS               = module.vpc.private_subnet_ids
  EC2_INSTANCE_TYPE                = var.EC2_INSTANCE_TYPE
  EC2_INSTANCE_AMI                 = var.EC2_INSTANCE_AMI
  IAM_ROLE_DEPENDENCY_FRONTEND_ECS = [module.iam.ecs_task_execution_role, module.iam.ecs_task_role]
  IAM_ROLE_DEPENDENCY_BACKEND_ECS  = [module.iam.ecs_task_execution_role, module.iam.ecs_task_role]
  FRONTEND_ECS_SECURITY_GROUP_ID   = module.security_groups.frontend_instances_security_group
  BACKEND_ECS_SECURITY_GROUP_ID    = module.security_groups.backend_instances_security_group
  EC2_KEY_PAIR_NAME                = aws_key_pair.ec2.key_name
  EC2_INSTANCE_PROFILE_NAME        = module.iam.ec2_instance_profile_name
  AVAILABILITY_ZONES               = var.AVAILABILITY_ZONES
  VPC                              = module.vpc.vpc_id
  INTERNAL_SERVICE_NAME            = var.INTERNAL_SERVICE_NAME
  BACKEND_ALB_DNS_NAME             = module.alb.backend_alb_dns_name
  FRONTEND_ALB_DNS_NAME            = module.alb.frontend_alb_dns_name
  depends_on                       = [module.vault]
}

