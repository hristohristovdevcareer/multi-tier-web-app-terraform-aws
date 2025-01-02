output "ecs_cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "web_app_repository_url" {
  value = var.FRONTEND_ECR_REPO
}

output "server_repository_url" {
  value = var.BACKEND_ECR_REPO
}