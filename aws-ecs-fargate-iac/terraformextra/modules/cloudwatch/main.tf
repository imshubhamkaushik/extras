# cloudwatch/main.tf

resource "aws_cloudwatch_log_group" "ecs" {
  for_each = toset(var.service_names)

  name              = "/ecs/${each.value}"
  retention_in_days = var.retention_days
}

# ECS CPU Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_names[0] # Assuming first service for simplicity
  }

  alarm_description = "Alarm when ECS CPU exceeds 80%"
}

# ALB Unhealthy Host Alarm
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
    TargetGroup  = aws_lb_target_group.frontend_svc.arn_suffix
  }

  alarm_description = "Alarm when ALB has unhealthy hosts"
}

# CloudWatch Dashboards
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.project_name}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_names[1]]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "ECS CPU Utilization (Service name - ${var.service_names[1]})"
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 0
        width = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_names[2]]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "ECS CPU Utilization (Service name - ${var.service_names[2]})"
        }
      },
      {
        type = "metric"
        x    = 6
        y    = 0
        width = 6
        height = 6
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