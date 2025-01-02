output "alb_security_group" {
  value = aws_security_group.alb.id
}

output "rds_security_group" {
  value = aws_security_group.rds.id
}

output "backend_ecs_security_group" {
  value = aws_security_group.backend_ecs.id
}

output "frontend_ecs_security_group" {
  value = aws_security_group.frontend_ecs.id
}

output "nat_sg" {
  value = aws_security_group.nat.id
}