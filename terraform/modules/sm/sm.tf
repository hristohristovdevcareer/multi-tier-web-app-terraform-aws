resource "aws_ssm_parameter" "internal_certificate" {
  name        = "/${var.PROJECT_NAME}/internal-certificate"
  description = "Internal self-signed certificate for backend services"
  type        = "SecureString"
  value       = var.INTERNAL_CERTIFICATE

  tags = {
    Name        = "${var.PROJECT_NAME}-internal-certificate"
    Environment = "production"
  }
}

# Store the backend ALB DNS name in SSM Parameter Store
resource "aws_ssm_parameter" "backend_alb_dns" {
  name        = "/${var.PROJECT_NAME}/backend-alb-dns"
  description = "Backend ALB DNS name for frontend to connect to"
  type        = "String"
  value       = "https://${var.BACKEND_ALB_DNS_NAME}"

  tags = {
    Name        = "${var.PROJECT_NAME}-backend-alb-dns"
    Environment = "production"
  }
}