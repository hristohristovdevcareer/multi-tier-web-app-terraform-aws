

# Frontend Launch Template
resource "aws_launch_template" "frontend" {
  name          = "frontend-launch-template"
  instance_type = var.EC2_INSTANCE_TYPE
  image_id      = var.EC2_IMAGE_ID

  #key only used for debugging, delete after successful implementation
  key_name = var.EC2_KEY

  iam_instance_profile {
    name = var.EC2_IAM_PROFILE_NAME
  }

  user_data = base64encode(<<EOT
      #!/bin/bash
      set -ex

      # Logging
      LOG_FILE="/var/log/user_data.log"
      exec > >(tee -a $LOG_FILE) 2>&1

      # ECS Configuration
      mkdir -p /etc/ecs
      echo "ECS_CLUSTER=${var.ECS_CLUSTER}" >> /etc/ecs/ecs.config
      echo "ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"awslogs\"]" >> /etc/ecs/ecs.config

      # Install Docker
      apt-get update
      apt-get install -y apt-transport-https ca-certificates curl software-properties-common awscli
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
      add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      apt-get update
      apt-get install -y docker-ce

      # Start Docker
      systemctl enable docker
      systemctl start docker
      usermod -aG docker ubuntu

      # Install ECS Agent
      curl -o /usr/local/bin/ecs-agent-init.sh https://raw.githubusercontent.com/aws/amazon-ecs-agent/master/scripts/ecs-agent-init.sh
      chmod +x /usr/local/bin/ecs-agent-init.sh
      /usr/local/bin/ecs-agent-init.sh

      # Start ECS Agent
      docker run --name ecs-agent \
        --detach=true \
        --restart=on-failure:10 \
        --volume=/var/run:/var/run \
        --volume=/var/log/ecs/:/log \
        --volume=/var/lib/ecs/data:/data \
        --volume=/etc/ecs:/etc/ecs \
        --net=host \
        --env-file=/etc/ecs/ecs.config \
        amazon/amazon-ecs-agent:latest

      # SSH Setup (GitLab Integration)
      mkdir -p /home/ubuntu/.ssh
      chmod 700 /home/ubuntu/.ssh
      touch /home/ubuntu/.ssh/known_hosts
      chmod 644 /home/ubuntu/.ssh/known_hosts
      ssh-keyscan -t rsa gitlab.com >> /home/ubuntu/.ssh/known_hosts
      echo "${var.GITLAB_PRIVATE_KEY}" | base64 --decode > /home/ubuntu/.ssh/gitlab_rsa
      chmod 400 /home/ubuntu/.ssh/gitlab_rsa
      echo "${var.GITLAB_PUBLIC_KEY}" > /home/ubuntu/.ssh/gitlab_rsa.pub

      # ECR Login and Application Setup
      aws ecr get-login-password --region ${var.REGION} | \
      docker login --username AWS --password-stdin ${var.FE_ECR_REPO}
      docker pull ${var.FE_ECR_REPO}:latest
      docker run -d -p 3000:3000 ${var.FE_ECR_REPO}:latest
      EOT
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.FE_SECURITY_GROUP]
  }

  tags = {
    Name = "frontend-launch-template"
  }
}
