variable "project_name" {
  type        = string
  description = "Logical name of the project"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}

variable "private_rds" {
  description = "List of private subnet IDs for RDS"
  type        = list(string)  
}

variable "rds_sg_id" {
  description = "Security group ID for the RDS instance"
  type        = string
}

variable "db_port" {
  description = "Port on which the database listens"
  type        = number
  default     = 5432  
}