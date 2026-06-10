# networking.tf

# ALB in public subnets with security groups allowing inbound traffic from the internet
# ECS in private app subnets with NAT Gateway for outbound access
# RDS in private db subnets with no internet access
# NAT Gateway for outbound internet access from ECS tasks

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public subnets for ALB
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-public-${count.index}"
  }
}

# Private subnets for ECS tasks
resource "aws_subnet" "private_ecs" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 4)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-ecs-${count.index}"
  }
}

# Private subnets for RDS
resource "aws_subnet" "private_rds" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 8)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-rds-${count.index}"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.nat.id

  depends_on = [aws_internet_gateway.this]
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

# Route table for private subnets with NAT Gateway (ECS)
resource "aws_route_table" "private_ecs" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
}

# Route table for private subnets without NAT Gateway (RDS)
resource "aws_route_table" "private_rds" {
  vpc_id = aws_vpc.this.id
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private ECS subnets with the private ECSroute table
resource "aws_route_table_association" "private_ecs" {
  count          = length(aws_subnet.private_ecs)
  subnet_id      = aws_subnet.private_ecs[count.index].id
  route_table_id = aws_route_table.private_ecs.id
}

# Associate private RDS subnets with the private RDS route table
resource "aws_route_table_association" "private_rds" {
  count          = length(aws_subnet.private_rds)
  subnet_id      = aws_subnet.private_rds[count.index].id
  route_table_id = aws_route_table.private_rds.id
}

# Availability Zones
data "aws_availability_zones" "available" {}
