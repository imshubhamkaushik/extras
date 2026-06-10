locals {
  autoscaling_config = {
    frontend = {
      service_name = aws_ecs_service.frontend_svc.name
      min_tasks    = 1
      max_tasks    = 2
      cpu_target   = 70 # Scale out at 70% CPU usage
      mem_target   = 75 # Scale out at 75% Memory usage
    }
    user = {
      service_name = aws_ecs_service.user_svc.name
      min_tasks    = 1
      max_tasks    = 2
      cpu_target   = 70 # Scale out at 70% CPU usage
      mem_target   = 75 # Scale out at 75% Memory usage
    }
    product = {
      service_name = aws_ecs_service.product_svc.name
      min_tasks    = 1
      max_tasks    = 2
      cpu_target   = 70 # Scale out at 70% CPU usage
      mem_target   = 75 # Scale out at 75% Memory usage
    }
  }
}

# AUTOSCALING TARGETS
resource "aws_appautoscaling_target" "ecs" {
  for_each = local.autoscaling_config

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"

  # aws_ecs_cluster.this.name = "${var.project_name}-cluster" = "catalogix-cluster"
  resource_id = "service/${aws_ecs_cluster.this.name}/${each.value.service_name}"

  min_capacity = each.value.min_tasks
  max_capacity = each.value.max_tasks

  depends_on = [
    aws_ecs_service.frontend_svc,
    aws_ecs_service.user_svc,
    aws_ecs_service.product_svc
  ]
}

# CPU SCALING POLICIES
resource "aws_appautoscaling_policy" "ecs_cpu" {
  for_each = local.autoscaling_config

  name               = "${var.project_name}-${each.key}-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs[each.key].service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs[each.key].scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs[each.key].resource_id

  target_tracking_scaling_policy_configuration {
    target_value       = each.value.cpu_target
    scale_in_cooldown  = 300 # 5 min - wait before removing tasks
    scale_out_cooldown = 60  # 1 min - wait before adding tasks

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# MEMORY SCALING POLICIES
resource "aws_appautoscaling_policy" "ecs_memory" {
  for_each = local.autoscaling_config

  name               = "${var.project_name}-${each.key}-memory-target-tracking"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs[each.key].service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs[each.key].scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs[each.key].resource_id

  target_tracking_scaling_policy_configuration {
    target_value       = each.value.mem_target
    scale_in_cooldown  = 300 # 5 min - wait before removing tasks
    scale_out_cooldown = 60  # 1 min - wait before adding tasks

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}