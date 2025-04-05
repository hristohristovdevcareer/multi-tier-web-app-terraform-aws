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
    command = <<EOT
      # Export environment variables for docker-compose
      export PROJECT_NAME="${var.PROJECT_NAME}"
      export IMAGE_TAG="${var.IMAGE_TAG}"
      export NEXT_PUBLIC_SERVER_URL="${var.NEXT_PUBLIC_SERVER_URL}"
      export AWS_REGION="${var.AWS_REGION}"
      
      # For web_app, fetch the certificate and create a temporary certificate file
      if [ "${each.key}" = "web_app" ]; then
        echo "Fetching certificate for web app..."
        mkdir -p ../client/certs
        aws ssm get-parameter --name "/${var.PROJECT_NAME}/internal-certificate" --with-decryption --query "Parameter.Value" --output text --region ${var.AWS_REGION} > ../client/certs/internal-ca.crt
        export NODE_EXTRA_CA_CERTS="/app/certs/internal-ca.crt"
      fi

      # Build with both build args and environment variables
      docker compose -f ${each.value.docker_compose} build \
        --build-arg NEXT_PUBLIC_SERVER_URL="${var.NEXT_PUBLIC_SERVER_URL}" \
        --build-arg PROJECT_NAME="${var.PROJECT_NAME}" \
        --build-arg IMAGE_TAG="${var.IMAGE_TAG}" \
        --build-arg AWS_REGION="${var.AWS_REGION}" \
        --build-arg CLIENT_URL="${var.CLIENT_URL}"

      # Login to ECR
      aws ecr get-login-password --region ${var.AWS_REGION} | \
      docker login --username AWS --password-stdin ${each.value.repo_url}

      # Tag and push
      docker tag ${each.value.project_name}:${var.IMAGE_TAG} ${each.value.repo_url}:${var.IMAGE_TAG}
      docker push ${each.value.repo_url}:${var.IMAGE_TAG}
      
      # Clean up the certificate file
      if [ "${each.key}" = "web_app" ]; then
        rm -rf ./client/certs
      fi
    EOT
  }

  depends_on = [
    aws_ecr_repository.web_app_repository,
    aws_ecr_repository.server_repository
  ]
}
