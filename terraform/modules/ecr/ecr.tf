
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
  for_each = {
    web_app = {
      docker_compose = var.SERVICES["web_app"].docker_compose
      dockerfile     = var.SERVICES["web_app"].dockerfile
      project_name   = "${var.PROJECT_NAME}-${var.SERVICES["web_app"].project_name}"
      repo_url       = aws_ecr_repository.web_app_repository.repository_url
    }
    server = {
      docker_compose = var.SERVICES["server"].docker_compose
      dockerfile     = var.SERVICES["server"].dockerfile
      project_name   = "${var.PROJECT_NAME}-${var.SERVICES["server"].project_name}"
      repo_url       = aws_ecr_repository.server_repository.repository_url
    }
  }

  triggers = {
    docker_compose = each.value.docker_compose
    dockerfile     = each.value.dockerfile
    version_tag    = var.IMAGE_TAG
    repo_url       = each.value.repo_url
  }

  provisioner "local-exec" {
    environment = {
      PROJECT_NAME = var.PROJECT_NAME
      IMAGE_TAG    = var.IMAGE_TAG
      # DB_HOST      = var.DB_HOST
      # DB_NAME      = var.DB_NAME
      # DB_USER      = var.DB_USER
      # DB_PASSWORD  = var.DB_PASSWORD
    }

    command = <<EOT
      #Need variables here
      docker-compose -f ${each.value.docker_compose} build 

      aws ecr get-login-password --region ${var.REGION} | \
      docker login --username AWS --password-stdin ${each.value.repo_url}

      docker tag ${each.value.project_name}:${var.IMAGE_TAG} ${each.value.repo_url}:${var.IMAGE_TAG}
      docker push ${each.value.repo_url}:${var.IMAGE_TAG}
    EOT
  }

  depends_on = [
    aws_ecr_repository.web_app_repository,
    aws_ecr_repository.server_repository
  ]
}
