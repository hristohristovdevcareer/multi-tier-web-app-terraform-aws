provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

# Key Pair for the EC2 instance
resource "aws_key_pair" "ec2" {
  key_name   = "ec-2-key"
  public_key = var.SSH_EC2
}

module "vpc" {
  source = "./modules/vpc"

  CIDR_VPC           = var.CIDR_VPC
  AVAILABILITY_ZONES = ["eu-west-2a"]
  NAT_INSTANCE_AMI   = var.NAT_INSTANCE_AMI
  NAT_INSTANCE_TYPE  = var.NAT_INSTANCE_TYPE
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
  EC2_IAM_PROFILE_NAME = aws_iam_instance_profile.ec2_ecr_instance_profile.name
  ECS_CLUSTER          = aws_ecs_cluster.main.name
  GITLAB_PRIVATE_KEY   = var.GITLAB_PRIVATE_KEY
  GITLAB_PUBLIC_KEY    = var.GITLAB_PUBLIC_KEY
  REGION               = var.REGION
  FE_ECR_REPO          = aws_ecr_repository.web_app_repository.repository_url
  FE_SECURITY_GROUP    = aws_security_group.frontend_ecs.id
}

module "backend" {
  source = "./modules/backend"

  EC2_INSTANCE_TYPE    = var.EC2_INSTANCE_TYPE
  EC2_INSTANCE_NAME    = var.EC2_INSTANCE_NAME
  EC2_KEY              = aws_key_pair.ec2.key_name
  EC2_INSTANCE_AMI     = var.EC2_INSTANCE_AMI
  EC2_IAM_PROFILE_NAME = aws_iam_instance_profile.ec2_ecr_instance_profile.name
  ECS_CLUSTER          = aws_ecs_cluster.main.name
  GITLAB_PRIVATE_KEY   = var.GITLAB_PRIVATE_KEY
  GITLAB_PUBLIC_KEY    = var.GITLAB_PUBLIC_KEY
  REGION               = var.REGION
  BE_ECR_REPO          = aws_ecr_repository.server_repository.repository_url
  BE_SECURITY_GROUP    = aws_security_group.backend_ecs.id
}

# Docker Compose and Dockerfile paths for each service
variable "services" {
  default = {
    web_app = {
      docker_compose = "${path.module}/../../../docker/web-app-compose.prod.yml"
      dockerfile     = "${path.module}/../../../docker/web-app.Dockerfile"
      project_name   = "web-app"
      ecr_repo_url   = aws_ecr_repository.web_app_repository.repository_url
    }
    server = {
      docker_compose = "${path.module}/../../../docker/server-compose.prod.yml"
      dockerfile     = "${path.module}/../../../docker/server.Dockerfile"
      project_name   = "server"
      ecr_repo_url   = aws_ecr_repository.server_repository.repository_url
    }
  }
}

module "iam" {
  source = "./modules/iam"
}

module "ecr" {
  source = "./modules/ecr"

  REGION       = var.REGION
  PROJECT_NAME = "web-app"
  SERVICES     = var.services
}

module "ecs" {
  source = "./modules/ecs"

  FRONTEND_ECR_REPO = aws_ecr_repository.web_app_repository.repository_url
  BACKEND_ECR_REPO  = aws_ecr_repository.server_repository.repository_url
  CLUSTER_ID        = aws_ecs_cluster.main.id
  FRONTEND_TARGET_GROUP_ARN = aws_lb_target_group.frontend.arn
  BACKEND_TARGET_GROUP_ARN = aws_lb_target_group.backend.arn
}

module "alb" {
  source = "./modules/alb"

  FRONTEND_LAUNCH_TEMPLATE_ID = aws_launch_template.frontend.id
  BACKEND_LAUNCH_TEMPLATE_ID  = aws_launch_template.backend.id
  PUBLIC_SUBNET_IDS          = module.vpc.public_subnet_ids
  PRIVATE_SUBNET_IDS         = module.vpc.private_subnet_ids
  VPC_ID                    = module.vpc.vpc_id
  ALB_SECURITY_GROUP_ID     = aws_security_group.alb.id
}

module "tf_state" {
  source = "./modules/tf-state"

  TF_STATE_BUCKET_NAME = local.BUCKET_NAME
  TABLE_NAME           = local.TABLE_NAME
}
