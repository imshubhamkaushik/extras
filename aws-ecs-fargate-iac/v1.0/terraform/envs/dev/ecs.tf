# ecs.tf

# ECS CLUSTER
# ECS cluster is the logical grouping for services and tasks.
# With Fargate, there are NO EC2 instances or node management.

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECS TASK DEFINITIONS
# Task Definition = blueprint for running containers.
# Execution role = ECS agent permissions (pull image, push logs)
# Task role = application permissions (empty for now)

# FRONTEND SERVICE TASK

resource "aws_ecs_task_definition" "frontend_svc" {
  family                   = "${var.project_name}-frontend-svc"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "frontend-svc"
      image = "${aws_ecr_repository.frontend_svc.repository_url}:init"

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend_svc.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
          mode                  = "non-blocking"
          max-buffer-size       = "25m"
        }
      }
    }
  ])
}

# USER SERVICE TASK

resource "aws_ecs_task_definition" "user_svc" {
  family                   = "${var.project_name}-user-svc"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "user-svc"
      image = "${aws_ecr_repository.user_svc.repository_url}:init"

      portMappings = [
        {
          containerPort = 8081
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SPRING_DATASOURCE_URL"
          value = "jdbc:postgresql://${aws_db_instance.postgres.address}:5432/${var.db_name}"
        },
        {
          name  = "ALLOWED_ORIGINS"
          value = "*"
        }
      ]

      secrets = [
        {
          name      = "SPRING_DATASOURCE_USERNAME"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:username::"
        },
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.user_svc.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
          mode                  = "non-blocking"
          max-buffer-size       = "25m"
        }
      }
    }
  ])
}

# PRODUCT SERVICE TASK

resource "aws_ecs_task_definition" "product_svc" {
  family                   = "${var.project_name}-product-svc"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "product-svc"
      image = "${aws_ecr_repository.product_svc.repository_url}:init"

      portMappings = [
        {
          containerPort = 8082
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SPRING_DATASOURCE_URL"
          value = "jdbc:postgresql://${aws_db_instance.postgres.address}:5432/${var.db_name}"
        },
        {
          name  = "ALLOWED_ORIGINS"
          value = "*"
        }
      ]

      secrets = [
        {
          name      = "SPRING_DATASOURCE_USERNAME"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:username::"
        },
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.product_svc.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
          mode                  = "non-blocking"
          max-buffer-size       = "25m"
        }
      }
    }
  ])
}


# ECS SERVICES
# Service ensures desired number of tasks are running and integrates ECS with ALB.

# FRONTEND SERVICE

resource "aws_ecs_service" "frontend_svc" {
  name            = "frontend-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend_svc.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  network_configuration {
    subnets          = aws_subnet.private_ecs[*].id
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_svc.arn
    container_name   = "frontend-svc"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}

# USER SERVICE

resource "aws_ecs_service" "user_svc" {
  name                              = "user-svc"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.user_svc.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 90

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  network_configuration {
    subnets          = aws_subnet.private_ecs[*].id
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.user_svc.arn
    container_name   = "user-svc"
    container_port   = 8081
  }

  depends_on = [aws_lb_listener.http]
}

# PRODUCT SERVICE

resource "aws_ecs_service" "product_svc" {
  name                              = "product-svc"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.product_svc.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 90

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  network_configuration {
    subnets          = aws_subnet.private_ecs[*].id
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.product_svc.arn
    container_name   = "product-svc"
    container_port   = 8082
  }

  depends_on = [aws_lb_listener.http]

}