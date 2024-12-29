# Security Group for the ALB (should be created first)
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP and HTTPS traffic to ALB"
  vpc_id      = var.VPC
}

# Security Group for the Frontend ECS
resource "aws_security_group" "frontend_ecs" {
  name        = "frontend-ecs-sg"
  description = "Allow traffic from ALB to Frontend ECS"
  vpc_id      = var.VPC

  depends_on = [
    aws_security_group.alb,
  ]
}

# Security Group for the Backend ECS
resource "aws_security_group" "backend_ecs" {
  name        = "backend-ecs-sg"
  description = "Allow traffic from Frontend ECS to Backend ECS"
  vpc_id      = var.VPC

  depends_on = [
    aws_security_group.frontend_ecs,
  ]
}

# Security Group for the RDS
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow traffic from Backend ECS to RDS"
  vpc_id      = var.VPC

  depends_on = [aws_security_group.backend_ecs]
}

# Now add the rules as separate resources to avoid circular dependencies
resource "aws_security_group_rule" "alb_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# Frontend ECS from ALB
resource "aws_security_group_rule" "frontend_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.frontend_ecs.id
}

# Frontend ECS SSH
resource "aws_security_group_rule" "frontend_ssh" {
  count             = var.ALLOW_SSH ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_ecs.id
}

# Backend ECS SSH
resource "aws_security_group_rule" "backend_ssh" {
  count             = var.ALLOW_SSH ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_ecs.id
}

# Backend ECS from Frontend ECS
resource "aws_security_group_rule" "backend_from_frontend" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend_ecs.id
  security_group_id        = aws_security_group.backend_ecs.id
}

# RDS from Backend ECS 
resource "aws_security_group_rule" "rds_from_backend" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend_ecs.id
  security_group_id        = aws_security_group.rds.id
}

# ALB egresss to the internet
resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# Frontend ECS egress to the internet
resource "aws_security_group_rule" "frontend_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_ecs.id
}

# Backend ECS egress to the internet
resource "aws_security_group_rule" "backend_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_ecs.id
}

# Allow ECS agent communication
resource "aws_security_group_rule" "ecs_agent" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_ecs.id
}

resource "aws_security_group_rule" "backend_ecs_agent" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_ecs.id
}