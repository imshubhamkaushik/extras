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
db_username = "postgres"
db_password = "your-secure-password"

frontend_image = "570538546471.dkr.ecr.ap-south-1.amazonaws.com/catalogix-frontend-svc:init"
user_image     = "570538546471.dkr.ecr.ap-south-1.amazonaws.com/catalogix-user-svc:init"
product_image  = "570538546471.dkr.ecr.ap-south-1.amazonaws.com/catalogix-product-svc:init"
