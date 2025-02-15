#!/bin/bash
export ECS_CLUSTER_NAME=${ECS_CLUSTER_NAME}
export LOG_GROUP_NAME=${LOG_GROUP_NAME}
export LOG_FILE=${LOG_FILE}
export ECS_CONTAINER_INSTANCE_TAGS=${ECS_CONTAINER_INSTANCE_TAGS}
export REGION=${REGION}

# Start the timer
start_time=$(date +%s)

# Log the start of the setup
echo "Starting ECS agent setup..." >> ${LOG_FILE} 2>&1

# Disable IPv6
echo "Disabling IPv6..." >> ${LOG_FILE} 2>&1
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
echo "net.ipv6.conf.all.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf

# Update and install required packages
echo "Updating system and installing dependencies..." >> ${LOG_FILE} 2>&1
sudo apt-get update -y >> ${LOG_FILE} 2>&1
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    docker.io -y  >> ${LOG_FILE} 2>&1

sudo snap install aws-cli --classic >> ${LOG_FILE} 2>&1

# Prevent iptables-persistent installation prompts
echo "Configuring iptables-persistent..." >> ${LOG_FILE} 2>&1
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | sudo debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | sudo debconf-set-selections

# Install iptables-persistent non-interactively
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent >> ${LOG_FILE} 2>&1

#Enable IP forwarding
echo "Enabling IP forwarding..." >> ${LOG_FILE} 2>&1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Configure networking for task IAM roles (ADD THIS SECTION HERE)
echo "Configuring networking for ECS task IAM roles..." >> ${LOG_FILE} 2>&1
sudo sysctl -w net.ipv4.conf.all.route_localnet=1 >> ${LOG_FILE} 2>&1
echo "net.ipv4.conf.all.route_localnet=1" | sudo tee -a /etc/sysctl.conf >> ${LOG_FILE} 2>&1

# Configure iptables for task IAM roles
echo "Configuring iptables rules for task IAM roles..." >> ${LOG_FILE} 2>&1

# Clear any existing rules for 169.254.170.2
sudo iptables -t nat -D PREROUTING -p tcp -d 169.254.170.2 -j DNAT --to-destination 127.0.0.1:51679 2>/dev/null || true
sudo iptables -t nat -D OUTPUT -p tcp -d 169.254.170.2 -j REDIRECT --to-ports 51679 2>/dev/null || true

# Add rules
sudo iptables -t nat -I PREROUTING 1 -p tcp -d 169.254.170.2 -j DNAT --to-destination 127.0.0.1:51679
sudo iptables -t nat -I OUTPUT 1 -p tcp -d 169.254.170.2 -j REDIRECT --to-ports 51679

# Get the primary network interface name
PRIMARY_INTERFACE=$(ip route get 8.8.8.8 | grep -oP "dev \K\S+")
echo "Primary network interface is: $PRIMARY_INTERFACE" >> ${LOG_FILE} 2>&1

# Configure network forwarding with detected interface
echo "Configuring network forwarding..." >> ${LOG_FILE} 2>&1
sudo iptables -P FORWARD ACCEPT
sudo iptables -A FORWARD -i docker0 -o $PRIMARY_INTERFACE -j ACCEPT
sudo iptables -A FORWARD -i $PRIMARY_INTERFACE -o docker0 -j ACCEPT

# Save iptables rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4 >> ${LOG_FILE} 2>&1

# Verify rules are saved
echo "Verifying iptables rules..." >> ${LOG_FILE} 2>&1
sudo iptables -t nat -S | grep 169.254.170.2 >> ${LOG_FILE} 2>&1

# Create CloudWatch log group before configuring Docker
echo "Creating CloudWatch log group..." >> ${LOG_FILE} 2>&1
aws logs create-log-group --log-group-name "${LOG_GROUP_NAME}" --region ${REGION} >> ${LOG_FILE} 2>&1


# Ensure systemd is using cgroup v2
echo "Configuring cgroup v2..." >> ${LOG_FILE} 2>&1
if ! mountpoint -q /sys/fs/cgroup; then
    sudo mount -t cgroup2 none /sys/fs/cgroup
fi

# Configure Docker daemon for cgroup v2
echo "Configuring Docker daemon..." >> ${LOG_FILE} 2>&1
cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "awslogs",
    "log-opts": {
        "awslogs-region": "${REGION}",
        "awslogs-group": "${LOG_GROUP_NAME}"
    }
}
EOF

# Configure Docker
echo "Configuring Docker..." >> ${LOG_FILE} 2>&1
sudo systemctl daemon-reload >> ${LOG_FILE} 2>&1
sudo systemctl restart docker >> ${LOG_FILE} 2>&1
sudo systemctl enable docker >> ${LOG_FILE} 2>&1
sudo usermod -aG docker ubuntu >> ${LOG_FILE} 2>&1

# Create ECS config directory and file
echo "Creating ECS configuration..." >> ${LOG_FILE} 2>&1
sudo mkdir -p /var/log/ecs /var/lib/ecs/data /etc/ecs
sudo chmod 755 /var/log/ecs
sudo touch /var/log/ecs/ecs-agent.log
sudo chmod 644 /var/log/ecs/ecs-agent.log
sudo touch /etc/ecs/ecs.config
sudo mkdir -p /var/lib/ecs/data

# Wait for Docker to be fully up
echo "Waiting for Docker to start..." >> ${LOG_FILE} 2>&1
sleep 10

# Verify Docker is running
if ! sudo docker info > /dev/null 2>&1; then
    echo "Docker is not running properly" >> ${LOG_FILE} 2>&1
    exit 1
fi

# Install CloudWatch Agent
sudo wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E amazon-cloudwatch-agent.deb 

# Configure CloudWatch Agent
echo "Configuring CloudWatch Agent..." >> ${LOG_FILE} 2>&1
cat <<EOF | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
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
  }
}
EOF

# Start CloudWatch Agent
echo "Starting CloudWatch Agent..." >> ${LOG_FILE} 2>&1
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo systemctl start amazon-cloudwatch-agent >> ${LOG_FILE} 2>&1
sudo systemctl enable amazon-cloudwatch-agent >> ${LOG_FILE} 2>&1

# Configure ECS Agent
echo "ECS_CLUSTER=${ECS_CLUSTER_NAME}" | sudo tee /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_CONTAINER_INSTANCE_TAGS=${ECS_CONTAINER_INSTANCE_TAGS}" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"awslogs\"]" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE=true" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_ENABLE_CONTAINER_METADATA=true" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
# 
echo "ECS_DATADIR=/var/lib/ecs/data" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_ENABLE_TASK_IAM_ROLE=true" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_RESERVED_PORTS=[\"22\",\"2375\",\"2376\",\"51678\",\"51679\"]" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_DISABLE_PRIVILEGED=false" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_AWSVPC_BLOCK_IMDS=false" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_ENABLE_SPOT_INSTANCE_DRAINING=true" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_LOGLEVEL=debug" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1  # Temporarily set to debug
echo "ECS_LOGFILE=/var/log/ecs/ecs-agent.log" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
#
echo "ECS_UPDATES_ENABLED=true" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_NETWORK_MODE=bridge" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=15m" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_WEBSOCKET_CONNECT_TIMEOUT=10s" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "ECS_WEBSOCKET_READ_TIMEOUT=60s" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1
echo "DOCKER_API_VERSION=1.42" | sudo tee -a /etc/ecs/ecs.config >> ${LOG_FILE} 2>&1

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
    --init \
    --restart=on-failure:10 \
    --volume=/var/run:/var/run \
    --volume=/var/log/ecs:/var/log/ecs \
    --volume=/var/lib/ecs/data:/var/lib/ecs/data \
    --volume=/etc/ecs:/etc/ecs \
    --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw \
    --volume=/run/systemd/private:/run/systemd/private \
    --volume=/run/systemd/system:/run/systemd/system \
    --privileged \
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
MAX_RETRIES=10
RETRY_INTERVAL=30
ATTEMPT=1

while [ $ATTEMPT -le $MAX_RETRIES ]; do
    if sudo docker ps | grep -q "ecs-agent"; then
        echo "ECS agent is running successfully." >> ${LOG_FILE} 2>&1

        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "ECS agent setup completed in $elapsed_time seconds." >> ${LOG_FILE} 2>&1

        exit 0
    else
        echo "Attempt $ATTEMPT: ECS agent not running yet. Waiting..." >> ${LOG_FILE} 2>&1
        sleep $RETRY_INTERVAL
        ATTEMPT=$((ATTEMPT + 1))
    fi
done


end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "ECS agent setup completed in $elapsed_time seconds." >> ${LOG_FILE} 2>&1

echo "Failed to verify ECS agent is running after $MAX_RETRIES attempts." >> ${LOG_FILE} 2>&1
exit 1