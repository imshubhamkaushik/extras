variable "project_name" {
  type = string
  description = "Name of the project"
}

variable "aws_region" {
  type    = string
  description = "AWS region"
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
  type = list(string)
  description = "List of CIDR blocks for public subnets"
}

variable "private_subnet_cidrs" {
  type = list(string)
  description = "List of CIDR blocks for private subnets"
}

variable "db_port" {
  type    = number
  description = "Port on which the database listens"
  default = 5432
}

variable "db_name" {
  type = string
  description = "Name of the PostgreSQL database for the application"
}

variable "db_username" {
  type = string
  description = "Username for the PostgreSQL database"
}

variable "db_password" {
  type      = string
  description = "Password for the PostgreSQL database"
  sensitive = true
}

variable "frontend_image" {
  type = string
  description = "Container image URI for the frontend service"
}

variable "user_image" {
  type = string
  description = "Container image URI for the user service"
}

variable "product_image" {
  type = string
  description = "Container image URI for the product service"
}
