output "frontend_tg_arn" {
  value = aws_lb_target_group.frontend_svc.arn
}

output "user_tg_arn" {
  value = aws_lb_target_group.user_svc.arn
}

output "product_tg_arn" {
  value = aws_lb_target_group.product_svc.arn
}
