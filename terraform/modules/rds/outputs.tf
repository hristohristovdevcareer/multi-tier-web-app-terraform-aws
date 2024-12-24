output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "The database username"
  value       = aws_db_instance.main.username
}

output "db_instance_password" {
  description = "The database password"
  value       = aws_db_instance.main.password
}
