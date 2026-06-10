variable "project_name" {
  type        = string
  description = "Logical name of the project"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-south-1"
}

variable "service_name" {
    type        = string
    description = "Name of the ECS service"
}

variable "cluster_id" {
    type        = string
    description = "ID of the ECS cluster"
}

variable "private_ecs" { 
  type = list(string) 
  description = "List of private subnet IDs for the ECS service"
}

variable "ecs_sg_id" {
    type        = string
    description = "Security group ID for the ECS service"
}

variable "image" {
    type        = string
    description = "Container image URI for the ECS service"
}

variable "container_port" {
    type        = number
    description = "Port on which the container listens"
}
variable "target_group_arn" {
    type        = string
    description = "ARN of the ALB target group for the ECS service"
}

variable "execution_role_arn" {
  type = string
  description = "ECS execution role ARN"
}
    
variable "task_role_arn" {
  type = string
  description = "ECS task role ARN"
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch log group name for the ECS service"
}

variable "db_url" {
  type        = string
  description = "Database connection URL for the ECS service"
  default = "jdbc:postgresql://${aws_db_instance.postgres.address}:5432/${var.db_name}"
}

variable "service_name_prefix" {
  type        = string
  description = "Prefix for CloudWatch log stream names"
  default     = "ecs"
}