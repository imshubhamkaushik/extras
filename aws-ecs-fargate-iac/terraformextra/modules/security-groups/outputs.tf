output "ecs_sg_id" {
  value = aws_security_group.ecs_service.id
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}