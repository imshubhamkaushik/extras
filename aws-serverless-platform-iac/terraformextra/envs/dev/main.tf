module "vpc" {
  source = "../../modules/vpc"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security_groups" {
  source = "../../modules/security-groups"
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
}

module "ecr" {
  source = "../../modules/ecr"

  project_name     = var.project_name
  repository_names = ["frontend-svc", "user-svc", "product-svc"]  
}

module "iam" {
  source       = "../../modules/iam"
  project_name = var.project_name
}

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"
  
  project_name = var.project_name
  cluster_name = "${var.project_name}-cluster"
}

module "cloudwatch" {
  source        = "../../modules/cloudwatch"

  project_name  = var.project_name
  cluster_name  = module.ecs_cluster.cluster_name
  service_names = ["frontend-svc", "user-svc", "product-svc"]
}

module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id

}

module "rds" {
  source = "../../modules/rds"

  project_name       = var.project_name
  private_rds = module.vpc.private_rds
  rds_sg_id = module.security_groups.rds_sg_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
}

module "frontend_service" {
  source = "../../modules/ecs-services"

  project_name      = var.project_name
  service_name      = "frontend-svc"
  cluster_id        = module.ecs_cluster.cluster_id
  db_url = "jdbc:postgresql://${aws_db_instance.postgres.address}:5432/${var.db_name}"
  private_ecs        = module.vpc.private_ecs
  ecs_sg_id = module.security_groups.ecs_sg_id
  image             = var.frontend_image
  container_port    = 80
  target_group_arn  = module.alb.frontend_tg_arn

  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  log_group_name     = module.cloudwatch.log_group_names["frontend-svc"]
  aws_region             = var.aws_region
}

module "user_service" {
  source = "../../modules/ecs-services"

  project_name      = var.project_name
  service_name      = "user-svc"
  cluster_id        = module.ecs_cluster.cluster_id
  db_url = "jdbc:postgresql://${aws_db_instance.postgres.address}:5432/${var.db_name}"
  private_ecs        = module.vpc.private_ecs
  ecs_sg_id = module.security_groups.ecs_sg_id
  image             = var.user_image
  container_port    = 8081
  target_group_arn  = module.alb.user_tg_arn

  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  log_group_name     = module.cloudwatch.log_group_names["user-svc"]
  aws_region             = var.aws_region
}

module "product_service" {
  source = "../../modules/ecs-services"

  project_name      = var.project_name
  service_name      = "product-svc"
  cluster_id        = module.ecs_cluster.cluster_id
  db_url = "jdbc:postgresql://${aws_db_instance.postgres.address}:${module.rds.db_port}/${var.db_name}"
  private_ecs       = module.vpc.private_ecs
  ecs_sg_id = module.security_groups.ecs_sg_id
  image             = var.product_image
  container_port    = 8082
  target_group_arn  = module.alb.product_tg_arn

  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  log_group_name     = module.cloudwatch.log_group_names["product-svc"]
  aws_region             = var.aws_region
}
