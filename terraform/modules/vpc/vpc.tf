
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

# Single NAT Gateway in the first availability zone
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[var.AVAILABILITY_ZONES[0]].id

  tags = {
    Name = "nat-gateway"
  }
}

# Single Elastic IP for the NAT Gateway
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

# Route Table for the private subnets, using the single NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
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
