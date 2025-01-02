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
  port        = 80
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

# Frontend Listener
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}