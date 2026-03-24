variable "vpc_id" {
    description = "VPC ID to create all security groups in."
    type        = string
}
variable "vpc_cidr" {
    description = "VPC CIDR block — used to restrict internal-only rules to VPC traffic"
    type        = string
}

variable "admin_cidr" {
    description = "Your IP in CIDR notation for SSH/UI access"
    type        = string
}