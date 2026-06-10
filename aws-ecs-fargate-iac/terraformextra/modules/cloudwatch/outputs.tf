output "log_group_names" {
  value = {
    for k, v in aws_cloudwatch_log_group.ecs :
    k => v.name
  }
}