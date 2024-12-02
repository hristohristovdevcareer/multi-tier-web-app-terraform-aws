
# ECR Repository for the Web App (Frontend)
resource "aws_ecr_repository" "web_app_repository" {
  name = "${var.PROJECT_NAME}-web-app-docker"

  tags = {
    Name = "web-app-repository"
  }
}

# ECR Repository for the Server App (Backend)
resource "aws_ecr_repository" "server_repository" {
  name = "${var.PROJECT_NAME}-server-docker"

  tags = {
    Name = "server-repository"
  }
}

# Outputs for the web app repository URL
output "web_app_ecr_repository_url" {
  value = aws_ecr_repository.web_app_repository.repository_url
}

# Outputs for the server repository URL
output "server_ecr_repository_url" {
  value = aws_ecr_repository.server_repository.repository_url
}

# Docker build and push for each service
resource "null_resource" "docker_build_and_push" {
  for_each = var.SERVICES

  triggers = {
    docker_compose = each.value.docker_compose
    dockerfile     = each.value.dockerfile
    version_tag    = "v.1.0.0"
  }

  provisioner "local-exec" {
    command = <<EOT
      docker-compose -f ${each.value.docker_compose} build

      aws ecr get-login-password --region ${var.REGION} | \
      docker login --username AWS --password-stdin ${each.value.ecr_repo_url}

      docker tag ${each.value.project_name}:${version_tag} ${each.value.ecr_repo_url}:${version_tag}
      docker push ${each.value.ecr_repo_url}:${version_tag}
    EOT
  }
}