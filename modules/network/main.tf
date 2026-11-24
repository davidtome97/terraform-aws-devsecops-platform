# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.name_prefix}-vpc"
    Project = var.project_name
  }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.name_prefix}-igw"
    Project = var.project_name
  }
}

# PUBLIC SUBNET
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id

  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name    = "${var.name_prefix}-public-subnet"
    Project = var.project_name
  }
}

# PRIVATE SUBNET
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id

  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name    = "${var.name_prefix}-private-subnet"
    Project = var.project_name
  }
}

# PUBLIC ROUTE TABLE
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.name_prefix}-public-rt"
    Project = var.project_name
  }
}

# PUBLIC ROUTE
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# PUBLIC ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# PRIVATE ROUTE TABLE
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.name_prefix}-private-rt"
    Project = var.project_name
  }
}

# PRIVATE ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}