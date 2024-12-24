data "aws_caller_identity" "current" {}


# IAM Role for EC2 to access ECR
resource "aws_iam_role" "ec2_ecr_role" {
  name = "ec2-ecr-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "ec2-ecr-role"
  }
}

# IAM Policy for the role to access ECR
resource "aws_iam_role_policy" "ec2_ecr_policy" {
  name = "ec2-ecr-access-policy"
  role = aws_iam_role.ec2_ecr_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*" # This one needs to be * as it's a global action
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = [
          "arn:aws:ecr:${var.REGION}:${data.aws_caller_identity.current.account_id}:repository/${var.PROJECT_NAME}-web-app-docker/*",
          "arn:aws:ecr:${var.REGION}:${data.aws_caller_identity.current.account_id}:repository/${var.PROJECT_NAME}-server-docker/*"
        ]
      }
    ]
  })
}

# IAM Instance Profile for the role to access ECR
resource "aws_iam_instance_profile" "ec2_ecr_instance_profile" {
  name = "ec2-ecr-access"
  role = aws_iam_role.ec2_ecr_role.name

  tags = {
    Name = "ec2-ecr-instance-profile"
  }
}

# Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ecs-task-execution-role"
  }
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Role (if your containers need to access AWS services)
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ecs-task-role"
  }
}

# Add specific permissions your containers need
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "ecs-task-role-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Permissions for CloudWatch Logs
          "logs:CreateLogStream",
          "logs:PutLogEvents",

          # Permissions for ECR
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",

          # Permissions for ECS Service Discovery (if you're using it)
          "servicediscovery:DiscoverInstances",

          # Add ALB permissions since you're using load balancers
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:RegisterTargets"
        ]
        Resource = [
          "arn:aws:ecr:${var.REGION}:${data.aws_caller_identity.current.account_id}:repository/${var.PROJECT_NAME}-web-app-docker",
          "arn:aws:ecr:${var.REGION}:${data.aws_caller_identity.current.account_id}:repository/${var.PROJECT_NAME}-server-docker",
          "arn:aws:logs:${var.REGION}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/*",
          "arn:aws:elasticloadbalancing:${var.REGION}:${data.aws_caller_identity.current.account_id}:*"
        ]
      }
    ]
  })
}
