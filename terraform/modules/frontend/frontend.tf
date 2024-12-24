

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
    echo ECS_CLUSTER=${var.ECS_CLUSTER} >> /etc/ecs/ecs.config

    LOG_FILE="/var/log/user_data.log"
    exec > >(tee -a $LOG_FILE) 2>&1

    # Update and install Docker
    apt-get update -y && apt-get install -y docker.io || { echo "Docker installation failed"; exit 1; }
    sudo apt install aws-cli --classic

    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    sudo docker run --name ecs-agent \
    --detach=true \
    --restart=always \
    --network=host \
    --env=ECS_CLUSTER=${var.ECS_CLUSTER} \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    --volume=/var/log/ecs/:/log \
    --volume=/var/lib/ecs/data:/data \
    --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
    amazon/amazon-ecs-agent:latest

    # Set up SSH directory and permissions
    mkdir -p /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh

    # Create known_hosts file
    touch /home/ubuntu/.ssh/known_hosts
    chmod 644 /home/ubuntu/.ssh/known_hosts
    echo "Created known_hosts"

    # Ensure gitlab.com is a known host
    ssh-keyscan -t rsa gitlab.com >> /home/ubuntu/.ssh/known_hosts
    echo "Gitlab host ssh scanned and added to known_hosts"

    # Set up SSH keys
    echo "${var.GITLAB_PRIVATE_KEY}" | base64 --decode > /home/ubuntu/.ssh/gitlab_rsa
    chmod 400 /home/ubuntu/.ssh/gitlab_rsa
    echo "${var.GITLAB_PUBLIC_KEY}" > /home/ubuntu/.ssh/gitlab_rsa.pub
    echo "SSH keys set up"

    # Log in to ECR
    aws ecr get-login-password --region ${var.REGION} | \
    docker login --username AWS --password-stdin ${var.FE_ECR_REPO} || { echo "ECR login failed"; exit 1; }

    # Pull the Docker image
    docker pull ${var.FE_ECR_REPO}:latest || { echo "Docker pull failed"; exit 1; }

    # Run the Docker container
    docker run -d -p 3000:3000 -e ${var.FE_ECR_REPO}:latest || { echo "Docker run failed"; exit 1; }
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