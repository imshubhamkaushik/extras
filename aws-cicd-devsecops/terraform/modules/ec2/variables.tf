variable "name" {
    description = "Name of the EC2 instance"
    type        = string
}

variable "ami" {
    description = "AMI ID for the EC2 instance"
    type        = string
}

variable "instance_type" { 
    description = "EC2 instance type"
    type        = string
}

variable "subnet_id" {
    description = "Subnet ID for the EC2 instance to launch into"
    type        = string
}

variable "vpc_id" {
    description = "VPC ID for the EC2 instance"
    type        = string
}

variable "key_name" {
    description = "Name of the EC2 key pair to use for SSH access"
    type        = string
}

variable "security_group_id" {
    description = "Security group ID for the EC2 instance"
    type        = string
}

variable "project_tag" {
    description = "Project tag for the EC2 instance and associated resources"
    type        = string
}

variable "role" {
    description = "Role tag for the EC2 instance and associated resources"
    type        = string
}