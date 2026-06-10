# secrets.tf

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}/database-credentials"
  description = "Database credentials for PostgreSQL database"

  # Set this to 0 to force immediate deletion upon 'terraform destroy'
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}