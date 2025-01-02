#!/bin/bash
export ECS_CLUSTER_NAME=${ECS_CLUSTER_NAME}
export LOG_FILE=${LOG_FILE}

# Log the start of the setup
echo "Starting ECS agent setup..." >> ${LOG_FILE} 2>&1

# Install Docker
echo "Installing Docker..." >> ${LOG_FILE} 2>&1
sudo apt-get update -y >> ${LOG_FILE} 2>&1 && sudo apt-get install -y docker.io >> ${LOG_FILE} 2>&1 || { echo "Docker installation failed"; exit 1; }

# Install AWS CLI using snap
echo "Installing AWS CLI..." >> ${LOG_FILE} 2>&1
sudo snap install aws-cli --classic >> ${LOG_FILE} 2>&1

# Start and enable Docker
echo "Starting and enabling Docker..." >> ${LOG_FILE} 2>&1
sudo systemctl start docker >> ${LOG_FILE} 2>&1 || { echo "Failed to start Docker"; exit 1; }
sudo systemctl enable docker >> ${LOG_FILE} 2>&1 || { echo "Failed to enable Docker"; exit 1; }

# Add the user to the Docker group
echo "Adding user to Docker group..." >> ${LOG_FILE} 2>&1
sudo usermod -aG docker ubuntu >> ${LOG_FILE} 2>&1

# Create ECS configuration and pull ECS agent image
echo "Creating ECS configuration and pulling ECS agent..." >> ${LOG_FILE} 2>&1
sudo mkdir -p /etc/ecs >> ${LOG_FILE} 2>&1
sudo touch /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
sudo docker pull amazon/amazon-ecs-agent:latest >> ${LOG_FILE} 2>&1

# Set ECS cluster name in the ECS config
echo "ECS_CLUSTER=${ECS_CLUSTER_NAME}" | sudo tee /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1

# Set ECS container instance tags in the ECS config
echo "ECS_CONTAINER_INSTANCE_TAGS=${ECS_CONTAINER_INSTANCE_TAGS}" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1

# Set ECS container instance propagate tags from EC2 instance in the ECS config
echo "ECS_CONTAINER_INSTANCE_PROPAGATE_TAGS_FROM=${ECS_CONTAINER_INSTANCE_PROPAGATE_TAGS_FROM}" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1

# Create systemd service for ECS agent
echo "Creating ECS systemd service..." >> ${LOG_FILE} 2>&1
cat <<EOF | sudo tee /lib/systemd/system/ecs.service > /dev/null
[Unit]
Description=Amazon ECS Agent
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=/etc/ecs/ecs.config
ExecStart=/usr/bin/docker run --name ecs-agent \
  --network=host \
  --restart=always \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --volume=/var/log/ecs:/log \
  --volume=/var/lib/ecs/data:/data \
  amazon/amazon-ecs-agent:latest
  --cluster ${ECS_CLUSTER_NAME}
ExecStop=/usr/bin/docker stop ecs-agent
ExecStopPost=/usr/bin/docker rm ecs-agent
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon and start ECS service
echo "Starting ECS service..." >> ${LOG_FILE} 2>&1
sudo systemctl daemon-reload >> ${LOG_FILE} 2>&1
sudo systemctl enable ecs >> ${LOG_FILE} 2>&1
sudo systemctl start ecs >> ${LOG_FILE} 2>&1

# Verify if ECS agent is running
echo "Verifying ECS agent status..." >> ${LOG_FILE} 2>&1
docker ps | grep ecs-agent >> ${LOG_FILE} 2>&1 || { echo "ECS agent container not running"; exit 1; }

echo "ECS Agent setup complete." >> ${LOG_FILE} 2>&1