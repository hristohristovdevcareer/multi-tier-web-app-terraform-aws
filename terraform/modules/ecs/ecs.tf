# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "custom-ecs-cluster"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = "/ecs/cluster"
      }
    }
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "ecs-cluster"
  }
}

# Update the cluster capacity providers association
resource "aws_ecs_cluster_capacity_providers" "cluster_capacity" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [
    aws_ecs_capacity_provider.frontend_capacity_provider.name,
    aws_ecs_capacity_provider.backend_capacity_provider.name
  ]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 50
    capacity_provider = aws_ecs_capacity_provider.frontend_capacity_provider.name
  }

  default_capacity_provider_strategy {
    weight            = 50
    capacity_provider = aws_ecs_capacity_provider.backend_capacity_provider.name
  }
}

# Create the EC2 capacity providers
resource "aws_ecs_capacity_provider" "frontend_capacity_provider" {
  name = "frontend-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.frontend-autoscaling-group.arn
    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 70
    }
  }
}

resource "aws_ecs_capacity_provider" "backend_capacity_provider" {
  name = "backend-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.backend-autoscaling-group.arn
    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 70
    }
  }
}


# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend-task-definition" {
  family                   = "frontend-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "128"
  memory                   = "256"
  task_role_arn            = var.ECS_TASK_ROLE_ARN
  execution_role_arn       = var.ECS_TASK_EXECUTION_ROLE_ARN

  container_definitions = jsonencode([{
    name  = "frontend-task"
    image = "${var.BACKEND_ECR_REPO}:${var.IMAGE_TAG}"
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/frontend"
        awslogs-region        = var.REGION
        awslogs-stream-prefix = "frontend"
      }
    }
    environment = [
      {
        name  = "SERVER_URL"
        value = var.SERVER_URL
      },
      {
        name  = "NODE_ENV"
        value = "production"
      },
      {
        name  = "PROJECT_NAME"
        value = var.PROJECT_NAME
      },
      {
        name  = "IMAGE_TAG"
        value = var.IMAGE_TAG
      }
    ]
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      }, {
      containerPort = 80
      hostPort      = 80
      }, {
      containerPort = 443
      hostPort      = 443
    }]
    essential = true
  }])

  tags = {
    Name = "frontend-task"
  }
}

# Backend Task Definition
resource "aws_ecs_task_definition" "backend-task-definition" {
  family                   = "backend-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "128"
  memory                   = "512"
  task_role_arn            = var.ECS_TASK_ROLE_ARN
  execution_role_arn       = var.ECS_TASK_EXECUTION_ROLE_ARN

  container_definitions = jsonencode([{
    name  = "backend-task"
    image = "${var.BACKEND_ECR_REPO}:${var.IMAGE_TAG}"
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/backend"
        awslogs-region        = var.REGION
        awslogs-stream-prefix = "backend"
      }
    }
    environment = [
      {
        name  = "DB_HOST"
        value = var.DB_HOST
      },
      {
        name  = "DB_NAME"
        value = var.DB_NAME
      },
      {
        name  = "DB_USER"
        value = var.DB_USER
      },
      {
        name  = "DB_PASSWORD"
        value = var.DB_PASSWORD
      },
      {
        name  = "NODE_ENV"
        value = "production"
      },
      {
        name  = "PROJECT_NAME"
        value = var.PROJECT_NAME
      },
      {
        name  = "IMAGE_TAG"
        value = var.IMAGE_TAG
      }
    ]
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
      }, {
      containerPort = 80
      hostPort      = 80
      }, {
      containerPort = 443
      hostPort      = 443
    }]
    essential = true
  }])

  tags = {
    Name = "backend-task"
  }
}


# ECS Service for Frontend
resource "aws_ecs_service" "frontend-service" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend-task-definition.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.frontend_capacity_provider.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = var.FRONTEND_TARGET_GROUP_ARN
    container_name   = aws_ecs_task_definition.frontend-task-definition.family
    container_port   = 3000
  }

  tags = {
    Name = "frontend-service"
  }

  depends_on = [var.IAM_ROLE_DEPENDENCY_FRONTEND_ECS]
}

# ECS Service for Backend
resource "aws_ecs_service" "backend-service" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend-task-definition.arn
  desired_count   = 1


  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.backend_capacity_provider.name
    weight            = 100
  }

  tags = {
    Name = "backend-service"
  }

  depends_on = [var.IAM_ROLE_DEPENDENCY_BACKEND_ECS]
}


resource "aws_appautoscaling_target" "frontend-app-autoscaling-target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.frontend-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_cpu" {
  name               = "frontend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend-app-autoscaling-target.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend-app-autoscaling-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend-app-autoscaling-target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_target" "backend-app-autoscaling-target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "backend_cpu" {
  name               = "backend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend-app-autoscaling-target.resource_id
  scalable_dimension = aws_appautoscaling_target.backend-app-autoscaling-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend-app-autoscaling-target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_autoscaling_group" "frontend-autoscaling-group" {
  launch_template {
    id      = aws_launch_template.frontend-template.id
    version = "$Latest"
  }
  min_size         = length(var.AVAILABILITY_ZONES)
  max_size         = length(var.AVAILABILITY_ZONES) * 2
  desired_capacity = length(var.AVAILABILITY_ZONES)
  vpc_zone_identifier = var.PUBLIC_SUBNET_IDS

  # Force spread across AZs
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "AG_GROUP-FRONTEND"
    value               = "frontend-ag-group"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "backend-autoscaling-group" {
  launch_template {
    id      = aws_launch_template.backend-template.id
    version = "$Latest"
  }
  min_size         = length(var.AVAILABILITY_ZONES)
  max_size         = length(var.AVAILABILITY_ZONES) * 2
  desired_capacity = length(var.AVAILABILITY_ZONES)
  vpc_zone_identifier = var.PRIVATE_SUBNET_IDS

  # Force spread across AZs
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "AG_GROUP-BACKEND"
    value               = "backend-ag-group"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "frontend_scale_out" {
  name                   = "frontend-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend-autoscaling-group.name
}

resource "aws_autoscaling_policy" "frontend_scale_in" {
  name                   = "frontend-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend-autoscaling-group.name
}

resource "aws_autoscaling_policy" "backend_scale_out" {
  name                   = "backend-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend-autoscaling-group.name
}

resource "aws_autoscaling_policy" "backend_scale_in" {
  name                   = "backend-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend-autoscaling-group.name
}

resource "aws_launch_template" "frontend-template" {
  name          = "frontend-launch-template"
  image_id      = var.EC2_INSTANCE_AMI
  instance_type = var.EC2_INSTANCE_TYPE

  key_name               = var.EC2_KEY_PAIR_NAME
  vpc_security_group_ids = [var.FRONTEND_ECS_SECURITY_GROUP_ID]

  iam_instance_profile {
    name = var.EC2_INSTANCE_PROFILE_NAME
  }

  user_data = base64encode(templatefile("${path.module}/../../startup.sh.tpl", {
    ECS_CLUSTER_NAME            = aws_ecs_cluster.main.name
    LOG_FILE                    = "/var/log/user_data.log"
    ECS_CONTAINER_INSTANCE_TAGS = replace(jsonencode({ "AG_GROUP-FRONTEND" = "frontend-ag-group" }), "\"", "\\\"")
    MAX_RETRIES                 = 5
    RETRY_INTERVAL              = 10
  }))

  tags = {
    Name = "frontend-launch-template"
  }
}

resource "aws_launch_template" "backend-template" {
  name          = "backend-launch-template"
  image_id      = var.EC2_INSTANCE_AMI  # Replace with your AMI ID
  instance_type = var.EC2_INSTANCE_TYPE # Replace with your desired instance type

  key_name               = var.EC2_KEY_PAIR_NAME
  vpc_security_group_ids = [var.BACKEND_ECS_SECURITY_GROUP_ID]


  iam_instance_profile {
    name = var.EC2_INSTANCE_PROFILE_NAME
  }

  user_data = base64encode(templatefile("${path.module}/../../startup.sh.tpl", {
    ECS_CLUSTER_NAME            = aws_ecs_cluster.main.name
    LOG_FILE                    = "/var/log/user_data.log"
    ECS_CONTAINER_INSTANCE_TAGS = replace(jsonencode({ "AG_GROUP-BACKEND" = "backend-ag-group" }), "\"", "\\\"")
    MAX_RETRIES                 = 5
    RETRY_INTERVAL              = 10
  }))

  tags = {
    Name = "backend-launch-template"
  }
}

resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name              = "/ecs/frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name              = "/ecs/backend"
  retention_in_days = 7
}
