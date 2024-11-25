provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

# VPC for the web app
resource "aws_vpc" "main" {
  cidr_block = var.CIDR_VPC
  tags       = { Name = "main-vpc" }
}

# Internet Gateway for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

variable "availability_zones" {
  default = ["eu-west-2a"]
}

resource "aws_subnet" "public" {
  for_each          = toset(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.CIDR_VPC, 4, index(var.availability_zones, each.key))
  availability_zone = each.key
  
  # Enable auto-assign public IP
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${each.key}"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  for_each          = toset(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.CIDR_VPC, 4, index(var.availability_zones, each.key))
  availability_zone = each.key

  tags = {
    Name = "private-subnet-${each.key}"
  }
}

# NAT Gateway for the private subnet
resource "aws_instance" "nat" {
  ami           = var.EC2_INSTANCE_AMI
  instance_type = var.EC2_INSTANCE_TYPE
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "nat-instance"
  }
}

# Elastic IP for the NAT Gateways
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

# Route Table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Route Table for the private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_instance.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Route Table Association for the public subnet
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Route Table Association for the private subnet
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Security Group for the ALB
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP and HTTPS traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# Security Group for the Frontend ECS
resource "aws_security_group" "frontend_ecs" {
  name        = "frontend-ecs-sg"
  description = "Allow traffic from ALB to Frontend ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ALLOW_SSH ? ["${chomp(data.http.my_ip.body)}/32"] : []
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "frontend-ecs-sg"
  }
}

# Security Group for the Backend ECS
resource "aws_security_group" "backend_ecs" {
  name        = "backend-ecs-sg"
  description = "Allow traffic from Frontend ECS to Backend ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ALLOW_SSH ? ["${chomp(data.http.my_ip.body)}/32"] : []
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend-ecs-sg"
  }
}

# Security Group for the RDS
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow traffic from Backend ECS to RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "alb_security_group" {
  value = aws_security_group.alb.id
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "custom-ecs-cluster"

  tags = {
    Name = "ecs-cluster"
  }
}

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

# Docker Compose and Dockerfile paths for each service
variable "services" {
  default = {
    web_app = {
      docker_compose = "${path.module}/../docker/web-app-compose.prod.yml"
      dockerfile     = "${path.module}/../docker/web-app.Dockerfile"
      project_name   = "web-app"
      ecr_repo_url   = aws_ecr_repository.web_app_repository.repository_url
    }
    server = {
      docker_compose = "${path.module}/../docker/server-compose.prod.yml"
      dockerfile     = "${path.module}/../docker/server.Dockerfile"
      project_name   = "server"
      ecr_repo_url   = aws_ecr_repository.server_repository.repository_url
    }
  }
}

# Docker build and push for each service
resource "null_resource" "docker_build_and_push" {
  for_each = var.services

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

# IAM Role for EC2 to access ECR
resource "aws_iam_role" "ec2_ecr_role" {
  name = "EC2_ECR_Access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "ec2-ecr-role"
  }
}

# IAM Policy for the role to access ECR
resource "aws_iam_role_policy" "ec2_ecr_policy" {
  name = "EC2_ECR_Access_Policy"
  role = aws_iam_role.ec2_ecr_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ],
        Resource = "*"
      },
    ]
  })
}

# IAM Instance Profile for the role to access ECR
resource "aws_iam_instance_profile" "ec2_ecr_instance_profile" {
  name = "EC2_ECR_Access"
  role = aws_iam_role.ec2_ecr_role.name

  tags = {
    Name = "ec2-ecr-instance-profile"
  }
}

######################################################################

# Frontend Launch Template
resource "aws_launch_template" "frontend" {
  name          = "frontend-launch-template"
  instance_type = var.EC2_INSTANCE_TYPE
  image_id      = data.aws_ami.ecs.id

  #key only used for debugging, delete after successful implementation
  key_name = aws_key_pair.ec2.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ecr_instance_profile.name
  }

  user_data = base64encode(<<EOT
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config

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
    --env=ECS_CLUSTER=${aws_ecs_cluster.main.name} \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    --volume=/var/log/ecs/:/log \
    --volume=/var/lib/ecs/data:/data \
    --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
    amazon/amazon-ecs-agent:latest

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
    docker login --username AWS --password-stdin ${aws_ecr_repository.web_app_repository.repository_url} || { echo "ECR login failed"; exit 1; }

    # Pull the Docker image
    docker pull ${aws_ecr_repository.web_app_repository.repository_url}:latest || { echo "Docker pull failed"; exit 1; }

    # Run the Docker container
    docker run -d -p 3000:3000 ${aws_ecr_repository.web_app_repository.repository_url}:latest || { echo "Docker run failed"; exit 1; }
    EOT
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.frontend_ecs.id]
  }

  tags = {
    Name = "frontend-launch-template"
  }
}

# Backend Launch Template
resource "aws_launch_template" "backend" {
  name          = "backend-launch-template"
  instance_type = var.EC2_INSTANCE_TYPE
  image_id      = data.aws_ami.ecs.id

  #key only used for debugging, delete after successful implementation
  key_name = aws_key_pair.ec2.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ecr_instance_profile.name
  }

  user_data = base64encode(<<EOT
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    
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
    --env=ECS_CLUSTER=${aws_ecs_cluster.main.name} \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    --volume=/var/log/ecs/:/log \
    --volume=/var/lib/ecs/data:/data \
    --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
    amazon/amazon-ecs-agent:latest

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
    docker login --username AWS --password-stdin ${aws_ecr_repository.server_repository.repository_url} || { echo "ECR login failed"; exit 1; }

    # Pull the Docker image
    docker pull ${aws_ecr_repository.server_repository.repository_url}:latest || { echo "Docker pull failed"; exit 1; }

    # Run the Docker container
    docker run -d -p 8080:8080 ${aws_ecr_repository.server_repository.repository_url}:latest || { echo "Docker run failed"; exit 1; }
    EOT
  )

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.backend_ecs.id]
  }

  tags = {
    Name = "backend-launch-template"
  }
}

######################################################################

# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "frontend-container"
    image = "${aws_ecr_repository.web_app_repository.repository_url}:v.1.0.0"
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
  }])

  tags = {
    Name = "frontend-task"
  }
}

# Backend Task Definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "backend-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "backend-container"
    image = "${aws_ecr_repository.server_repository.repository_url}:v.1.0.0"
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
  }])

  tags = {
    Name = "backend-task"
  }
}

######################################################################

# ECS Service for Frontend
resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 2
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend-container"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "frontend-service"
  }
}

# ECS Service for Backend
resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "backend-service"
  }
}

######################################################################

# Frontend Auto Scaling Group
resource "aws_autoscaling_group" "frontend" {
  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  vpc_zone_identifier       = aws_subnet.public[*].id
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "frontend-asg"
    propagate_at_launch = true
  }
}

# Backend Auto Scaling Group
resource "aws_autoscaling_group" "backend" {
  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  vpc_zone_identifier       = aws_subnet.private[*].id
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "backend-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "main" {
  name                       = "main-alb"
  internal                   = false
  security_groups            = [aws_security_group.alb.id]
  subnets                    = aws_subnet.public[*].id
  enable_deletion_protection = false

  tags = {
    Name = "main-alb"
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "frontend-tg"
  }
}

resource "aws_lb_target_group" "backend" {
  name        = "backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  tags = {
    Name = "backend-tg"
  }
}

# Key Pair for the EC2 instance
resource "aws_key_pair" "ec2" {
  key_name   = "ec-2-key"
  public_key = var.SSH_EC2
}
