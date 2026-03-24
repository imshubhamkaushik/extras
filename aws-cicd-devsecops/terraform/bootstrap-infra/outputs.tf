output "public_ip_jenkins" {
    description = "Public IP of the Jenkins Server"
    value       = aws_instance.jenkins_catalogix.public_ip
}

output "public_ip_sonarqube" {
    description = "Public IP of the SonarQube Server"
    value       = aws_instance.sonarqube_catalogix.public_ip
}

output "vpc_id" {
    description = "VPC"
    value = aws_vpc.this.id
}

output "public_subnets" {
    description = "Public Subnets of VPC"
    value = aws_subnet.public[*].id
}

output "private_subnets" {
    description = "Private Subnets of VPC"
    value = aws_subnet.private[*].id
}