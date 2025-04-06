
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
  threshold           = 85
  alarm_description   = "This metric monitors ECS agent connectivity"

  dimensions = {
    ClusterName = var.ECS_CLUSTER_NAME
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