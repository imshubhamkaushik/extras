variable "service_names" {
  type = list(string)
  description = "List of ECS service names for which to create CloudWatch log groups"
}

variable "retention_days" {
  type    = number
  description = "Number of days to retain CloudWatch logs"
  default = 7
}

variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster for CloudWatch alarms"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-south-1"
}