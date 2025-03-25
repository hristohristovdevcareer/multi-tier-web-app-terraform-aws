output "frontend_target_group_arn" {
  value = aws_lb_target_group.frontend_target_group.arn
}

output "backend_target_group_arn" {
  value = aws_lb_target_group.backend_target_group.arn
}

output "backend_alb_dns_name" {
  value = aws_lb.backend_alb.dns_name
}

output "internal_certificate_pem" {
  value       = tls_self_signed_cert.internal.cert_pem
  sensitive   = true
  description = "The internal certificate in PEM format"
}

output "frontend_alb_dns_name" {
  value = aws_lb.frontend_alb.dns_name
}
