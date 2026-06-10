# rds.tf

# RDS SUBNET GROUP
# Tells AWS which subnets RDS is allowed to use.
# These are PRIVATE subnets only.

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private_rds[*].id
}

# RDS POSTGRESQL INSTANCE
# Managed PostgreSQL database.
# Single-AZ, small instance → cost-aware for dev.

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres"

  engine         = "postgres"
  engine_version = "15"

  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 0

  lifecycle {
    create_before_destroy = true
  }
}
