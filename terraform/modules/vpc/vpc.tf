
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
  cidr_block        = cidrsubnet(var.CIDR_VPC, 4, index(var.AVAILABILITY_ZONES, each.key))
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
  cidr_block        = cidrsubnet(var.CIDR_VPC, 4, index(var.AVAILABILITY_ZONES, each.key) + length(var.AVAILABILITY_ZONES))
  availability_zone = each.key

  tags = {
    Name = "private-subnet-${each.key}"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each = aws_subnet.private

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = {
    Name = "nat-instance-${each.key}"
  }
}

resource "aws_eip" "nat" {
  for_each = toset(var.AVAILABILITY_ZONES)

  domain = "vpc"

  tags = {
    Name = "nat-eip-${each.key}"
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
    nat_gateway_id = aws_nat_gateway.nat[var.AVAILABILITY_ZONES[0]].id
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
