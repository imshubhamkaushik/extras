locals {
  cluster_name = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_certificate = module.eks.cluster_certificate
}

data "aws_ami" "ubuntu_22" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

# VPC
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "catalogix-vpc"
  cidr_block = "10.0.0.0/16"
  cluster_name = "catalogix-dev"

  azs = ["ap-south-1a", "ap-south-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
}

# Security Groups
module "sg" {
  source   = "../../modules/security-groups"
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = "10.0.0.0/16"
  admin_cidr = "0.0.0.0/0"
}

# EKS
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "catalogix-dev"
  cluster_version = "1.29"
  instance_type = ["t2.micro"]
  private_subnets = module.vpc.private_subnets
}

# ECR
module "ecr" {
  source = "../../modules/ecr"
  repositories = ["frontend-svc", "user-svc", "product-svc"]
}

# ALB
module "alb" {
  source = "../../modules/alb"

  cluster_name      = module.eks.cluster_name
  vpc_id            = module.vpc.vpc_id
  region            = var.region
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = trimprefix(module.eks.oidc_provider_arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/")

  depends_on = [module.eks]
}

# EC2 - Jenkins
module "jenkins" {
  source = "../../modules/ec2"

  name        = "jenkins-server"
  ami         = data.aws_ami.ubuntu_22.id
  subnet_id   = module.vpc.public_subnets[0]
  vpc_id      = module.vpc.vpc_id
  key_name    = var.key_name
  security_group_id = module.sg.jenkins_sg
  project_tag = "catalogix"
  role = "jenkins"
  instance_type = "t2.medium"
}

# EC2 - SonarQube
module "sonarqube" {
  source = "../../modules/ec2"

  name        = "sonarqube-server"
  ami         = data.aws_ami.ubuntu_22.id
  subnet_id   = module.vpc.public_subnets[1]
  vpc_id      = module.vpc.vpc_id
  key_name    = var.key_name
  security_group_id = module.sg.sonar_sg
  project_tag = "catalogix"
  role = "sonarqube"
  instance_type = "t2.medium"
}

# RDS
module "rds" {
  source = "../../modules/rds"

  name            = "catalogix-db"
  db_name         = "catalogix"
  username        = "postgres"
  password        = var.db_password
  private_subnets = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  security_group_id = module.sg.rds_sg
}

# Secrets Manager
module "secrets" {
  source = "../../modules/secrets-manager"
  
  # Namespaced name avoids collision if you add more envs (staging, prod).
  secret_name = "${var.project_name}/dev/db-credentials"

  secret_values = {
    db_user = "postgres"
    db_pass = var.db_password
  }
}

