output "web_app_repository_url" {
  value = aws_ecr_repository.web_app_repository.repository_url
}

output "server_repository_url" {
  value = aws_ecr_repository.server_repository.repository_url
}