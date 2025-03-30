# VPC for the web app
resource "aws_vpc" "main" {
  cidr_block = var.CIDR_VPC

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "main-vpc" }
}

# Internet Gateway for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  for_each          = toset(var.AVAILABILITY_ZONES)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.CIDR_VPC, 3, index(var.AVAILABILITY_ZONES, each.key))
  availability_zone = each.key

  # Enable auto-assign public IP
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${each.key}"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  for_each          = toset(var.AVAILABILITY_ZONES)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.CIDR_VPC, 3, index(var.AVAILABILITY_ZONES, each.key) + length(var.AVAILABILITY_ZONES))
  availability_zone = each.key

  tags = {
    Name = "private-subnet-${each.key}"
  }
}

# Route Table for the public subnet
resource "aws_route_table" "public" {
  for_each = toset(var.AVAILABILITY_ZONES)
  vpc_id   = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# # Route Table for the private subnets, using NAT Instance
resource "aws_route_table" "private" {
  for_each = toset(var.AVAILABILITY_ZONES)
  vpc_id   = aws_vpc.main.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat[each.key].primary_network_interface_id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Route Table Association for the public subnet
resource "aws_route_table_association" "public" {
  for_each       = toset(var.AVAILABILITY_ZONES)
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}

# Route Table Association for the private subnet
resource "aws_route_table_association" "private" {
  for_each       = toset(var.AVAILABILITY_ZONES)
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_eip" "nat_eip" {
  for_each = toset(var.AVAILABILITY_ZONES)
  instance = aws_instance.nat[each.key].id
}

# NAT Instance
resource "aws_instance" "nat" {
  for_each      = toset(var.AVAILABILITY_ZONES)
  ami           = var.EC2_INSTANCE_AMI
  instance_type = var.EC2_INSTANCE_TYPE
  subnet_id     = aws_subnet.public[each.key].id

  # Enable source/destination check must be disabled for NAT
  source_dest_check = false

  vpc_security_group_ids = [var.NAT_SG]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              export LOG_FILE="/var/log/user_data.log"

              echo "Create known_hosts file..." >> $${LOG_FILE} 2>&1
              touch /home/ubuntu/.ssh/known_hosts
              chmod 644 /home/ubuntu/.ssh/known_hosts
              echo "Created known_hosts"

              echo "Ensure gitlab.com is a known host..." >> $${LOG_FILE} 2>&1
              ssh-keyscan -t rsa gitlab.com >> /home/ubuntu/.ssh/known_hosts
              echo "Gitlab host ssh scanned and added to known_hosts"

              echo "Set up SSH keys..." >> $${LOG_FILE} 2>&1
              echo "${var.NAT_KEY_PAIR_NAME}" | base64 --decode > /home/ubuntu/.ssh/nat_rsa
              chmod 400 /home/ubuntu/.ssh/nat_rsa

              echo "Update and install required packages..." >> $${LOG_FILE} 2>&1
              sudo apt-get update >> $${LOG_FILE} 2>&1

              echo "dpkg first init" >> $${LOG_FILE} 2>&1
              sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a >> $${LOG_FILE} 2>&1
              
              echo "kill apt and apt-get" >> $${LOG_FILE} 2>&1
              sudo killall apt apt-get >> $${LOG_FILE} 2>&1
              
              echo "dpkg second init" >> $${LOG_FILE} 2>&1
              sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a >> $${LOG_FILE} 2>&1

              echo "Preconfigure iptables-persistent to avoid interactive prompts..." >> $${LOG_FILE} 2>&1
              echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | sudo debconf-set-selections >> $${LOG_FILE} 2>&1
              echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | sudo debconf-set-selections >> $${LOG_FILE} 2>&1

              echo "install iptables-persistent" >> $${LOG_FILE} 2>&1
              sudo apt-get install -y iptables-persistent >> $${LOG_FILE} 2>&1

              echo "Enable IP forwarding..." >> $${LOG_FILE} 2>&1
              echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward >> $${LOG_FILE} 2>&1
              echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf >> $${LOG_FILE} 2>&1
  
              # TCP Keepalive
              echo 'net.ipv4.tcp_keepalive_time = 60' | sudo tee -a /etc/sysctl.conf >> $${LOG_FILE} 2>&1
              echo 'net.ipv4.tcp_keepalive_intvl = 10' | sudo tee -a /etc/sysctl.conf >> $${LOG_FILE} 2>&1
              echo 'net.ipv4.tcp_keepalive_probes = 6' | sudo tee -a /etc/sysctl.conf >> $${LOG_FILE} 2>&1
              sysctl -p >> $${LOG_FILE} 2>&1

               Add these lines here for NAT configuration
              echo "Detecting primary network interface..." >> $${LOG_FILE} 2>&1
              PRIMARY_INTERFACE=$(ip route get 8.8.8.8 | grep -oP "dev \K\S+")
              echo "Primary interface is: $PRIMARY_INTERFACE" >> $${LOG_FILE} 2>&1

              echo "NAT configuration..." >> $${LOG_FILE} 2>&1
              sudo iptables -t nat -F POSTROUTING
              sudo iptables -t nat -A POSTROUTING -o $PRIMARY_INTERFACE -j MASQUERADE >> $${LOG_FILE} 2>&1
              
              echo "Save iptables rules..." >> $${LOG_FILE} 2>&1
              sudo netfilter-persistent save >> $${LOG_FILE} 2>&1
              sudo netfilter-persistent reload >> $${LOG_FILE} 2>&1
              EOF
  )

  tags = {
    Name = "nat-instance"
  }
}



