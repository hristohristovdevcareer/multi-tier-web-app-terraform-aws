# VPC for the web app
resource "aws_vpc" "main" {
  cidr_block = var.CIDR_VPC
  tags       = { Name = "main-vpc" }
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
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Route Table for the private subnets, using NAT Instance
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
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

# NAT Instance
resource "aws_instance" "nat" {
  ami           = var.EC2_INSTANCE_AMI # Ubuntu 22.04 LTS in eu-west-2
  instance_type = var.EC2_INSTANCE_TYPE
  subnet_id     = aws_subnet.public[var.AVAILABILITY_ZONES[0]].id

  # Enable source/destination check must be disabled for NAT
  source_dest_check = false

  vpc_security_group_ids = [var.NAT_SG]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Update and install required packages
              apt-get update
              apt-get install -y iptables-persistent

              # Enable IP forwarding
              echo 1 > /proc/sys/net/ipv4/ip_forward
              echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

              # NAT configuration
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              
              # Save iptables rules
              netfilter-persistent save
              netfilter-persistent reload
              EOF
  )

  tags = {
    Name = "nat-instance"
  }
}