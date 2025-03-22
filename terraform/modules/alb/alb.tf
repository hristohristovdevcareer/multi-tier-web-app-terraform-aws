terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
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
resource "aws_lb_target_group" "frontend_target_group" {
  name        = "frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.VPC_ID
  target_type = "instance"

  health_check {
    path                = "/api/health"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  # Enable dynamic port mapping
  stickiness {
    type    = "lb_cookie"
    enabled = false
  }

  # Important: Allow using dynamic port mapping
  lifecycle {
    ignore_changes = [port]
  }

  tags = {
    Name = "frontend-tg"
  }
}

# Frontend Listener
resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
  }

  depends_on = [aws_acm_certificate_validation.main, cloudflare_record.cert_validation]
}

# HTTP listener to redirect to HTTPS
resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ACM Certificate
resource "aws_acm_certificate" "main" {
  domain_name       = var.DOMAIN_NAME
  validation_method = "DNS"

  tags = {
    Name = "main-certificate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Cloudflare DNS Record
resource "cloudflare_record" "alb" {
  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = var.DOMAIN_NAME
  content = aws_lb.main.dns_name
  type    = "CNAME"
  proxied = true # Enable Cloudflare's proxy features
}

# ACM Certificate Validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in cloudflare_record.cert_validation : record.hostname]
}

# Certificate Validation Records
resource "cloudflare_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = each.value.name
  content = each.value.record
  type    = each.value.type
  proxied = false # DNS validation records should not be proxied
  ttl     = 60
}

############################################################

# Internal ALB for backend services
resource "aws_lb" "backend_alb" {
  name                       = "backend-alb"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [var.BACKEND_ALB_SECURITY_GROUP_ID]
  subnets                    = var.PRIVATE_SUBNET_IDS
  enable_deletion_protection = false

  tags = {
    Name = "backend-alb"
  }
}

# Create a private key for internal services
resource "tls_private_key" "internal" {
  algorithm  = "RSA"
  rsa_bits   = 2048
  depends_on = [aws_lb.backend_alb]
}

# Create a self-signed certificate for internal services
resource "tls_self_signed_cert" "internal" {
  private_key_pem = tls_private_key.internal.private_key_pem

  subject {
    common_name  = "backend.${var.INTERNAL_SERVICE_NAME}"
    organization = "Internal Service"
  }

  validity_period_hours = 8760 # 1 year

  # Add the ALB DNS name as a Subject Alternative Name (SAN)
  dns_names = [
    "*.${var.INTERNAL_SERVICE_NAME}",
    "backend.${var.INTERNAL_SERVICE_NAME}",
    aws_lb.backend_alb.dns_name
  ]

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  depends_on = [aws_lb.backend_alb]
}

# Import the self-signed certificate into ACM
resource "aws_acm_certificate" "internal" {
  private_key      = tls_private_key.internal.private_key_pem
  certificate_body = tls_self_signed_cert.internal.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

# Backend Target Group
resource "aws_lb_target_group" "backend_target_group" {
  name        = "backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.VPC_ID
  target_type = "instance"

  health_check {
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200-299"
  }

  tags = {
    Name = "backend-tg"
  }
}

# Backend HTTPS Listener
resource "aws_lb_listener" "backend_https" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.internal.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_target_group.arn
  }
}

# Cleanup dependency
resource "null_resource" "cleanup_dependencies" {
  depends_on = [
    aws_lb_listener.backend_https,
    aws_acm_certificate.internal
  ]
}