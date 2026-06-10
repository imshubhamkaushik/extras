# iam/main.tf

# ECS Execution Role - Allows ECS tasks to pull container images and write logs to CloudWatch.
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { 
        Service = "ecs-tasks.amazonaws.com" 
      }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach the AWS-managed policy for ECS task execution to the role
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow the Execution Role to fetch secrets from Secrets Manager
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${var.project_name}-ecs-execution-secrets"
  role = aws_iam_role.ecs_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = [
        aws_secretsmanager_secret.db_credentials.arn
      ]
    }]
  })
}

# ECS Task Role - Role that ECS tasks assume when they run. Can be used to grant permissions to access other AWS services.
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task"

  assume_role_policy = aws_iam_role.ecs_execution.assume_role_policy
}
