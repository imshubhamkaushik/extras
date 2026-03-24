output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "jenkins_public_ip" {
  description = "Public IP of Jenkins EC2 — use for SSH and browser access"
  value       = module.jenkins.public_ip
}

output "sonarqube_public_ip" {
  description = "Public IP of SonarQube EC2 — access at http://<ip>:9000"
  value       = module.sonarqube.public_ip
}

output "rds_endpoint" {
  description = "RDS Postgres endpoint — use as SPRING_DATASOURCE_URL host"
  value       = module.rds.endpoint
}

output "ecr_registry" {
  description = "ECR registry base URL — used in Jenkinsfile as ECR_REGISTRY"
  value       = module.ecr.registry_url
}
