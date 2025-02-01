# Security Group for the ALB (should be created first)
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP and HTTPS traffic to ALB"
  vpc_id      = var.VPC
}

# Allow ALB to access container port 8080 on frontend instances
resource "aws_security_group_rule" "frontend_from_alb_app_port" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.frontend_instances.id
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

# Now add the rules as separate resources to avoid circular dependencies
resource "aws_security_group_rule" "alb_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# Security Group for the Frontend 
resource "aws_security_group" "frontend_instances" {
  name        = "frontend-ecs-sg"
  description = "Allow traffic from ALB to Frontend ECS"
  vpc_id      = var.VPC

  depends_on = [
    aws_security_group.alb,
  ]
}

# # Frontend ECS from ALB
# resource "aws_security_group_rule" "frontend_from_alb" {
#   type                     = "ingress"
#   from_port                = 80
#   to_port                  = 80
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.alb.id
#   security_group_id        = aws_security_group.frontend_instances.id
# }

# Frontend SSH
resource "aws_security_group_rule" "frontend_ssh" {
  count             = var.ALLOW_SSH ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_instances.id
}

# Frontend egress to the internet
resource "aws_security_group_rule" "frontend_egress_all_protocols" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_instances.id
}


# Allow ECS agent communication
resource "aws_security_group_rule" "frontend_instances_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_instances.id
}

# Allow Frontend ECS HTTP
resource "aws_security_group_rule" "frontend_instances_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_instances.id
}

# Frontend app port
resource "aws_security_group_rule" "frontend_instances_app_port" {
  type              = "ingress"
  from_port         = 32768
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_instances.id
}

# Allow ECS agent communication (port 51678)
resource "aws_security_group_rule" "frontend_ecs_agent" {
  type              = "ingress"
  from_port         = 51678
  to_port           = 51678
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # You might want to restrict this to VPC CIDR
  security_group_id = aws_security_group.frontend_instances.id
}

# Security Group for the Backend ECS
resource "aws_security_group" "backend_instances" {
  name        = "backend-ecs-sg"
  description = "Allow traffic from Frontend ECS to Backend ECS"
  vpc_id      = var.VPC

  depends_on = [
    aws_security_group.frontend_instances,
  ]
}

# Allow frontend to access container port 8080 on backend instances
resource "aws_security_group_rule" "backend_from_frontend_app_port" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend_instances.id
  security_group_id        = aws_security_group.backend_instances.id
}

# Backend ECS to NAT all protocols, all ports
resource "aws_security_group_rule" "backend_to_nat" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.backend_instances.id
  security_group_id        = aws_security_group.nat.id
}

# Backend SSH
resource "aws_security_group_rule" "backend_ssh" {
  count             = var.ALLOW_SSH ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_instances.id
}

# Backend from Frontend HTTP
resource "aws_security_group_rule" "backend_from_frontend_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend_instances.id
  security_group_id        = aws_security_group.backend_instances.id
}

# Backend from Frontend HTTPS
resource "aws_security_group_rule" "backend_from_frontend_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend_instances.id
  security_group_id        = aws_security_group.backend_instances.id
}


# Security Group for the RDS
# resource "aws_security_group" "rds" {
#   name        = "rds-sg"
#   description = "Allow traffic from Backend ECS to RDS"
#   vpc_id      = var.VPC

#   depends_on = [aws_security_group.backend_instances]
# }

# RDS from Backend 
# resource "aws_security_group_rule" "rds_from_backend" {
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.backend_instances.id
#   security_group_id        = aws_security_group.rds.id
# }

# Backend egress to the internet for all protocols
resource "aws_security_group_rule" "backend_egress_all_protocols" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_instances.id
}

# Allow ECS agent communication (port 51678)
resource "aws_security_group_rule" "backend_instances_ecs_agent" {
  type              = "ingress"
  from_port         = 51678
  to_port           = 51678
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_instances.id
}

# Allow Backend  HTTPS
resource "aws_security_group_rule" "backend_instances_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_instances.id
}

# Allow Backend  HTTP
resource "aws_security_group_rule" "backend_instances_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_instances.id
}

# Security group for NAT Instance
resource "aws_security_group" "nat" {
  name        = "nat-sg"
  description = "Security group for NAT instance"
  vpc_id      = var.VPC

  tags = {
    Name = "nat-security-group"
  }
}

resource "aws_security_group_rule" "nat_ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nat.id
}

# Backend SSH from NAT
resource "aws_security_group_rule" "backend_ssh_from_nat" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nat.id
  security_group_id        = aws_security_group.backend_instances.id
}

#Nat instance to backend 
resource "aws_security_group_rule" "nat_to_backend_instances" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.nat.id
  security_group_id        = aws_security_group.backend_instances.id
}


# NAT Instance ingress from Backend 
resource "aws_security_group_rule" "nat_ingress_from_backend" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.backend_instances.id
  security_group_id        = aws_security_group.nat.id
}

#NAT to the internet
resource "aws_security_group_rule" "nat_to_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nat.id
}
