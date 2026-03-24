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

variable "vpc_id" {
    description = "VPC ID for the EC2 instance"
    type        = string
}

variable "vpc_name" {
  description = "Base name for VPC resources"  
  type        = string
  default = "catalogix-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "admin_cidr" {
    description = "Your IP in CIDR notation for SSH/UI access"
    type        = string
}

variable "key_name" {
    description = "Name of the EC2 key pair to use for SSH access"
    type        = string
}

variable "project_tag" {
    description = "Project tag for the EC2 instance and associated resources"
    type        = string
    default     = "Catalogix"
}

variable "role" {
    description = "Role tag for the EC2 instance and associated resources"
    type        = string
}

variable "azs" {
  description = "List of availability zones to use for the subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of CIDR blocks for the public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of CIDR blocks for the private subnets"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "jenkins_sg" {
  description = "Security group ID for Jenkins"
  type        = string
  default     = aws_security_group.jenkins.id  
}

variable "sonarqube_sg" {
  description = "Security group ID for SonarQube"
  type        = string
  default     = aws_security_group.sonarqube.id  
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"  
}