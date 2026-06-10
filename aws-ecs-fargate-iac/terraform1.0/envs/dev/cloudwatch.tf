# cloudwatch.tf

resource "aws_cloudwatch_log_group" "frontend_svc" {
  name              = "/ecs/frontend-svc"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_cloudwatch_log_group" "user_svc" {
  name              = "/ecs/user-svc"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_cloudwatch_log_group" "product_svc" {
  name              = "/ecs/product-svc"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = false
  }
}

# ECS CPU Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  for_each = local.ecs_services

  alarm_name          = "${var.project_name}-${each.key}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  treat_missing_data = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = each.value
  }

  alarm_description = "Alarm when ECS CPU utilization on ${each.key} exceeds 80%"
}

# ECS Memory Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  for_each = local.ecs_services

  alarm_name          = "${var.project_name}-${each.key}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = each.value
  }

  alarm_description = "Alarm when ECS Memory utilization on ${each.key} exceeds 80%"
}

# ALB Unhealthy Host Alarm
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  for_each = local.target_groups

  alarm_name          = "${var.project_name}-${each.key}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1

  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
    TargetGroup  = each.value
  }

  alarm_description = "Alarm when ALB has unhealthy hosts for target group ${each.key}"
}

# CloudWatch Dashboards
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # CPU Utilization
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.user_svc.name]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "User Service CPU Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.product_svc.name]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Product Service CPU Utilization"
        }
      },
      # Memory Utilization
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.user_svc.name]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "User Service Memory Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.product_svc.name]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Product Service Memory Utilization"
        }
      },
      # ALB Request Count
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.this.arn_suffix]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Request Count"
        }
      },
      # Response Time
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.this.arn_suffix]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Target Response Time"
        }
      },
      # ALB 5XX Errors
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.this.arn_suffix]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB 5XX Errors"
        }
      },
      # ALB Unhealthy Hosts
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "UnhealthyHostCount", "LoadBalancer", aws_lb.this.arn_suffix, "TargetGroup", aws_lb_target_group.frontend_svc.arn_suffix]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Unhealthy Hosts"
        }
      }
    ]
  })
}

locals {
  ecs_services = {
    frontend = aws_ecs_service.frontend_svc.name,
    user = aws_ecs_service.user_svc.name,
    product = aws_ecs_service.product_svc.name,
  }

  target_groups = {
    frontend = aws_lb_target_group.frontend_svc.arn_suffix,
    user = aws_lb_target_group.user_svc.arn_suffix,
    product = aws_lb_target_group.product_svc.arn_suffix
  }
}