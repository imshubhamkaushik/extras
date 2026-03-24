variable "region" {
  default = "ap-south-1"
}

variable "key_name" {
  description = "Name of the EC2 key pair to use for SSH access to Jenkins and SonarQube"
  type        = string
  # No default — must be set in terraform.tfvars (gitignored).
  # Create a key pair in the AWS console or via aws ec2 create-key-pair.
}

variable "db_password" {
  description = "Master password for the RDS Postgres instance"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Logical name of the project"
  type = string  
}