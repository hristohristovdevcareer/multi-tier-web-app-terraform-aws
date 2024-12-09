
# Frontend Auto Scaling Group
resource "aws_autoscaling_group" "frontend" {
  launch_template {
    id      = var.FRONTEND_LAUNCH_TEMPLATE_ID
    version = "$Latest"
  }
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  vpc_zone_identifier       = var.PUBLIC_SUBNET_IDS
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "frontend-asg"
    propagate_at_launch = true
  }
}

# Backend Auto Scaling Group
resource "aws_autoscaling_group" "backend" {
  launch_template {
    id      = var.BACKEND_LAUNCH_TEMPLATE_ID
    version = "$Latest"
  }
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  vpc_zone_identifier       = var.PRIVATE_SUBNET_IDS
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "backend-asg"
    propagate_at_launch = true
  }
}

# ALB
resource "aws_lb" "main" {
  name                       = "main-alb"
  internal                   = false
  security_groups            = [var.ALB_SECURITY_GROUP_ID]
  subnets                    = var.PUBLIC_SUBNET_IDS
  enable_deletion_protection = false

  tags = {
    Name = "main-alb"
  }
}

# Frontend Target Group
resource "aws_lb_target_group" "frontend" {
  name        = "frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.VPC_ID
  target_type = "instance"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "frontend-tg"
  }
}

resource "aws_lb_target_group" "backend" {
  name        = "backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.VPC_ID
  target_type = "instance"

  tags = {
    Name = "backend-tg"
  }
}