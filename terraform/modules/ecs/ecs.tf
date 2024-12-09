
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "custom-ecs-cluster"

  tags = {
    Name = "ecs-cluster"
  }
}


# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "frontend-container"
    image = "${var.FRONTEND_ECR_REPO}:v.1.0.0"
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
  }])

  tags = {
    Name = "frontend-task"
  }
}

# Backend Task Definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "backend-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "backend-container"
    image = "${var.BACKEND_ECR_REPO}:v.1.0.0"
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
  }])

  tags = {
    Name = "backend-task"
  }
}


# ECS Service for Frontend
resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = var.CLUSTER_ID
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 2
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = var.FRONTEND_TARGET_GROUP_ARN
    container_name   = "frontend-container"
    container_port   = 3000
  }

  tags = {
    Name = "frontend-service"
  }
}

# ECS Service for Backend
resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = var.CLUSTER_ID
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = var.BACKEND_TARGET_GROUP_ARN
    container_name   = "backend-container"
    container_port   = 8080
  }

  tags = {
    Name = "backend-service"
  }
}
