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

# Cluster capacity providers association
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

# EC2 capacity providers
resource "aws_ecs_capacity_provider" "frontend_capacity_provider" {
  name = "frontend-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.frontend-autoscaling-group.arn
    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 85 #Use 70 in general, but 50 to simplify instance scaling
      instance_warmup_period    = 300
    }
    managed_termination_protection = "ENABLED"
  }
}

# Backend capacity provider
resource "aws_ecs_capacity_provider" "backend_capacity_provider" {
  name = "backend-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.backend-autoscaling-group.arn
    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 85 #Use 70 in general, but 50 to simplify instance scaling
      instance_warmup_period    = 300
    }
    managed_termination_protection = "ENABLED"
  }
}

# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend-task-definition" {
  family                   = "frontend-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "1024"
  memory                   = "1536"
  task_role_arn            = var.ECS_TASK_ROLE_ARN
  execution_role_arn       = var.ECS_TASK_EXECUTION_ROLE_ARN

  container_definitions = jsonencode([{
    memory            = 1536
    memoryReservation = 1536
    cpu               = 1024
    ulimits = [
      {
        name      = "nofile",
        softLimit = 65536,
        hardLimit = 65536
      }
    ]
    name  = "frontend-task"
    image = "${var.FRONTEND_ECR_REPO}:latest"
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group  = "/ecs/frontend"
        awslogs-region = var.REGION
      }
    }
    environment = [
      {
        name  = "PROJECT_NAME"
        value = var.PROJECT_NAME
      },
      {
        name  = "SERVER_URL"
        value = var.SERVER_URL
      },
      {
        name  = "NODE_ENV"
        value = "production"
      },
      {
        name  = "PORT"
        value = "3000"
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
      hostPort      = 0
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
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = var.ECS_TASK_ROLE_ARN
  execution_role_arn       = var.ECS_TASK_EXECUTION_ROLE_ARN

  container_definitions = jsonencode([{
    memory            = 512
    memoryReservation = 512
    cpu               = 256
    ulimits = [
      {
        name      = "nofile",
        softLimit = 4096,
        hardLimit = 4096
      },
      {
        name      = "nproc",
        softLimit = 2048,
        hardLimit = 4096
      },
      {
        name      = "core",
        softLimit = 0,
        hardLimit = 0
      }
    ]
    name  = "backend-task"
    image = "${var.BACKEND_ECR_REPO}:latest"
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group  = "/ecs/backend"
        awslogs-region = var.REGION
      }
    }
    environment = [
      {
        name  = "PROJECT_NAME"
        value = var.PROJECT_NAME
      },
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
      hostPort      = 0
    }]
    essential = true
  }])

  tags = {
    Name = "backend-task"
  }
}


# ECS Service for Frontend
resource "aws_ecs_service" "frontend-service" {
  name                              = "frontend-service"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.frontend-task-definition.arn
  desired_count                     = 1
  health_check_grace_period_seconds = 600 # Match 500-600s startup time

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.frontend_capacity_provider.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = var.FRONTEND_TARGET_GROUP_ARN
    container_name   = aws_ecs_task_definition.frontend-task-definition.family
    container_port   = 3000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name = "frontend-service"
  }

  depends_on = [var.IAM_ROLE_DEPENDENCY_FRONTEND_ECS, aws_autoscaling_group.frontend-autoscaling-group, aws_ecs_capacity_provider.frontend_capacity_provider]
}

# ECS Service for Backend
resource "aws_ecs_service" "backend-service" {
  name                              = "backend-service"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.backend-task-definition.arn
  desired_count                     = 1
  health_check_grace_period_seconds = 600 # Match 500-600s startup time

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.backend_capacity_provider.name
    weight            = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name = "backend-service"
  }

  depends_on = [var.IAM_ROLE_DEPENDENCY_BACKEND_ECS, aws_autoscaling_group.backend-autoscaling-group, aws_ecs_capacity_provider.backend_capacity_provider]
}


# Frontend autoscaling target
resource "aws_appautoscaling_target" "frontend-app-autoscaling-target" {
  max_capacity       = length(var.AVAILABILITY_ZONES) * 2
  min_capacity       = length(var.AVAILABILITY_ZONES)
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.frontend-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Frontend CPU scaling policy
resource "aws_appautoscaling_policy" "frontend_cpu" {
  name               = "frontend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend-app-autoscaling-target.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend-app-autoscaling-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend-app-autoscaling-target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 85.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300 #Use 600 for production but 180 for dev
    scale_out_cooldown = 180 #Use 300 for production but 120 for dev
  }
}

# Backend autoscaling target
resource "aws_appautoscaling_target" "backend-app-autoscaling-target" {
  max_capacity       = length(var.AVAILABILITY_ZONES) * 2
  min_capacity       = length(var.AVAILABILITY_ZONES)
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Backend CPU scaling policy
resource "aws_appautoscaling_policy" "backend_cpu" {
  name               = "backend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend-app-autoscaling-target.resource_id
  scalable_dimension = aws_appautoscaling_target.backend-app-autoscaling-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend-app-autoscaling-target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 85.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300 #Use 600 for production but 180 for dev
    scale_out_cooldown = 180 #Use 300 for production but 120 for dev
  }
}

# Frontend autoscaling group
resource "aws_autoscaling_group" "frontend-autoscaling-group" {
  launch_template {
    id      = aws_launch_template.frontend-template.id
    version = "$Latest"
  }
  min_size            = length(var.AVAILABILITY_ZONES)
  max_size            = length(var.AVAILABILITY_ZONES) * 2
  desired_capacity    = length(var.AVAILABILITY_ZONES)
  vpc_zone_identifier = var.PUBLIC_SUBNET_IDS

  force_delete          = true
  protect_from_scale_in = true

  metrics_granularity = "5Minute"

  # Force spread across AZs
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  tag {
    key                 = "AG_GROUP-FRONTEND"
    value               = "frontend-ag-group"
    propagate_at_launch = true
  }
}

# Backend autoscaling group
resource "aws_autoscaling_group" "backend-autoscaling-group" {
  launch_template {
    id      = aws_launch_template.backend-template.id
    version = "$Latest"
  }
  min_size            = length(var.AVAILABILITY_ZONES)
  max_size            = length(var.AVAILABILITY_ZONES) * 2
  desired_capacity    = length(var.AVAILABILITY_ZONES)
  vpc_zone_identifier = var.PRIVATE_SUBNET_IDS

  force_delete          = true
  protect_from_scale_in = true

  metrics_granularity = "5Minute"

  # Force spread across AZs
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  tag {
    key                 = "AG_GROUP-BACKEND"
    value               = "backend-ag-group"
    propagate_at_launch = true
  }
}

# Frontend scale out policy
resource "aws_autoscaling_policy" "frontend_scale_out" {
  name                   = "frontend-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120 #Use 300 for production but 120 for dev
  autoscaling_group_name = aws_autoscaling_group.frontend-autoscaling-group.name
}

# Frontend scale in policy
resource "aws_autoscaling_policy" "frontend_scale_in" {
  name                   = "frontend-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180 #Use 300 for production but 180 for dev
  autoscaling_group_name = aws_autoscaling_group.frontend-autoscaling-group.name
}

# Backend scale out policy
resource "aws_autoscaling_policy" "backend_scale_out" {
  name                   = "backend-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120 #Use 300 for production but 120 for dev
  autoscaling_group_name = aws_autoscaling_group.backend-autoscaling-group.name
}

# Backend scale in policy
resource "aws_autoscaling_policy" "backend_scale_in" {
  name                   = "backend-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180 #Use 300 for production but 180 for dev
  autoscaling_group_name = aws_autoscaling_group.backend-autoscaling-group.name
}

# Frontend launch template
resource "aws_launch_template" "frontend-template" {
  name          = "frontend-launch-template"
  image_id      = var.EC2_INSTANCE_AMI
  instance_type = "t3.small"

  key_name               = var.EC2_KEY_PAIR_NAME
  vpc_security_group_ids = [var.FRONTEND_ECS_SECURITY_GROUP_ID]

  iam_instance_profile {
    name = var.EC2_INSTANCE_PROFILE_NAME
  }

  user_data = base64encode(templatefile("${path.module}/../../startup_frontend.sh.tpl", {
    ECS_CLUSTER_NAME            = aws_ecs_cluster.main.name
    LOG_FILE                    = "/var/log/user_data.log"
    ECS_CONTAINER_INSTANCE_TAGS = replace(jsonencode({ "AG_GROUP-FRONTEND" = "frontend-ag-group" }), "\"", "\\\"")
    MAX_RETRIES                 = 5
    RETRY_INTERVAL              = 10
    LOG_GROUP_NAME              = "/ecs/frontend"
    REGION                      = var.REGION
  }))

  tags = {
    Name = "frontend-launch-template"
  }
}

# Backend launch template
resource "aws_launch_template" "backend-template" {
  name          = "backend-launch-template"
  image_id      = var.EC2_INSTANCE_AMI
  instance_type = var.EC2_INSTANCE_TYPE

  key_name               = var.EC2_KEY_PAIR_NAME
  vpc_security_group_ids = [var.BACKEND_ECS_SECURITY_GROUP_ID]


  iam_instance_profile {
    name = var.EC2_INSTANCE_PROFILE_NAME
  }

  user_data = base64encode(templatefile("${path.module}/../../startup_backend.sh.tpl", {
    ECS_CLUSTER_NAME            = aws_ecs_cluster.main.name
    LOG_FILE                    = "/var/log/user_data.log"
    ECS_CONTAINER_INSTANCE_TAGS = replace(jsonencode({ "AG_GROUP-BACKEND" = "backend-ag-group" }), "\"", "\\\"")
    MAX_RETRIES                 = 5
    RETRY_INTERVAL              = 10
    LOG_GROUP_NAME              = "/ecs/backend"
    REGION                      = var.REGION
  }))

  tags = {
    Name = "backend-launch-template"
  }
}

# Frontend log group
resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name              = "/ecs/frontend"
  retention_in_days = 1
}

# Backend log group
resource "aws_cloudwatch_log_group" "backend_log_group" {
  name              = "/ecs/backend"
  retention_in_days = 1
}

# ECS agent log group
resource "aws_cloudwatch_log_group" "ecs_agent" {
  name              = "/ecs/ecs-agent"
  retention_in_days = 1
}

# ECS agent connected metric alarm
resource "aws_cloudwatch_metric_alarm" "ecs_agent_connected" {
  alarm_name          = "ecs-agent-connected"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ContainerInstanceCount"
  namespace           = "AWS/ECS"
  period              = "300" # 5 minutes to stay within free tier
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ECS agent connectivity"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
  }
}

resource "aws_cloudwatch_log_metric_filter" "ecs_errors" {
  name           = "ecs-errors"
  pattern        = "[timestamp, level=ERROR, ...]"
  log_group_name = aws_cloudwatch_log_group.ecs_agent.name

  metric_transformation {
    name      = "ECSErrors"
    namespace = "ECS/Errors"
    value     = "1"
  }
}

# ECS errors dashboard
resource "aws_cloudwatch_dashboard" "ecs" {
  dashboard_name = "ecs-errors"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "log",
        properties = {
          query  = "fields @timestamp, @message | filter @message like /(?i)(error|failed|exception)/"
          region = var.REGION
          title  = "ECS Errors"
        }
      }
    ]
  })
}
