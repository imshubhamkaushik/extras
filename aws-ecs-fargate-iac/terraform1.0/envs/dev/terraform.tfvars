# Terraform variables for the development environment
aws_region = "ap-south-1"

environment = "dev"

project_name = "catalogix"

vpc_cidr = "10.0.0.0/16"

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

db_name     = "catalogix"
db_username = "catalogix"
db_password = "catalogix1234"