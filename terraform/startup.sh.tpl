#!/bin/bash
export ECS_CLUSTER_NAME=${ECS_CLUSTER_NAME}
export LOG_FILE=${LOG_FILE}
export ECS_CONTAINER_INSTANCE_TAGS=${ECS_CONTAINER_INSTANCE_TAGS}

# Log the start of the setup
echo "Starting ECS agent setup..." >> ${LOG_FILE} 2>&1

# Update and install required packages
echo "Updating system and installing dependencies..." >> ${LOG_FILE} 2>&1
sudo apt-get update -y >> ${LOG_FILE} 2>&1
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    docker.io -y  >> ${LOG_FILE} 2>&1

sudo wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb >> ${LOG_FILE} 2>&1
sudo dpkg -i -E amazon-cloudwatch-agent.deb >> ${LOG_FILE} 2>&1

# Configure CloudWatch Agent
echo "Configuring CloudWatch Agent..." >> ${LOG_FILE} 2>&1
cat <<EOF | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user_data.log",
            "log_group_name": "/ec2/user_data",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/ecs/ecs-agent.log",
            "log_group_name": "/ecs/ecs-agent",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/ecs/ecs-init.log",
            "log_group_name": "/ecs/ecs-init",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "docker": {
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch Agent
echo "Starting CloudWatch Agent..." >> ${LOG_FILE} 2>&1
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo systemctl start amazon-cloudwatch-agent >> ${LOG_FILE} 2>&1
sudo systemctl enable amazon-cloudwatch-agent >> ${LOG_FILE} 2>&1

# Configure Docker
echo "Configuring Docker..." >> ${LOG_FILE} 2>&1
sudo systemctl start docker >> ${LOG_FILE} 2>&1
sudo systemctl enable docker >> ${LOG_FILE} 2>&1
sudo usermod -aG docker ubuntu >> ${LOG_FILE} 2>&1

# Create ECS config directory and file
echo "Creating ECS configuration..." >> ${LOG_FILE} 2>&1
sudo mkdir -p /etc/ecs
sudo touch /etc/ecs/ecs.config

# Configure ECS Agent
echo "ECS_CLUSTER=${ECS_CLUSTER_NAME}" | sudo tee /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_CONTAINER_INSTANCE_TAGS=${ECS_CONTAINER_INSTANCE_TAGS}" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"awslogs\"]" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_ENABLE_CONTAINER_METADATA=true" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=1h" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1

# Create and configure ECS service
echo "Creating ECS systemd service..." >> ${LOG_FILE} 2>&1
cat <<EOF | sudo tee /etc/systemd/system/ecs.service
[Unit]
Description=Amazon Elastic Container Service - EC2 Agent
Documentation=https://docs.aws.amazon.com/AmazonECS/latest/developerguide/
Requires=docker.service
After=docker.service

[Service]
Type=simple
Restart=always
RestartSec=10
ExecStartPre=/bin/mkdir -p /var/log/ecs /var/lib/ecs/data /etc/ecs
ExecStart=/usr/bin/docker run --name ecs-agent \
    --restart=on-failure:10 \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    --volume=/var/log/ecs:/log \
    --volume=/var/lib/ecs/data:/data \
    --volume=/etc/ecs:/etc/ecs \
    --net=host \
    --env-file=/etc/ecs/ecs.config \
    amazon/amazon-ecs-agent:latest

[Install]
WantedBy=multi-user.target
EOF

# Start ECS service
echo "Starting ECS service..." >> ${LOG_FILE} 2>&1
sudo systemctl daemon-reload >> ${LOG_FILE} 2>&1
sudo systemctl enable ecs >> ${LOG_FILE} 2>&1
sudo systemctl start ecs >> ${LOG_FILE} 2>&1

# Verify ECS agent is running
echo "Verifying ECS agent status..." >> ${LOG_FILE} 2>&1
MAX_RETRIES=5
RETRY_INTERVAL=10
ATTEMPT=1

while [ $ATTEMPT -le $MAX_RETRIES ]; do
    if sudo docker ps | grep -q "ecs-agent"; then
        echo "ECS agent is running successfully." >> ${LOG_FILE} 2>&1
        exit 0
    else
        echo "Attempt $ATTEMPT: ECS agent not running yet. Waiting..." >> ${LOG_FILE} 2>&1
        sleep $RETRY_INTERVAL
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

echo "Failed to verify ECS agent is running after $MAX_RETRIES attempts." >> ${LOG_FILE} 2>&1
exit 1