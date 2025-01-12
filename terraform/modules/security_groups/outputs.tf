output "alb_security_group" {
  value = aws_security_group.alb.id
}

# output "rds_security_group" {
#   value = aws_security_group.rds.id
# }

output "backend_instances_security_group" {
  value = aws_security_group.backend_instances.id
}

output "frontend_instances_security_group" {
  value = aws_security_group.frontend_instances.id
}

output "nat_sg" {
  value = aws_security_group.nat.id
}