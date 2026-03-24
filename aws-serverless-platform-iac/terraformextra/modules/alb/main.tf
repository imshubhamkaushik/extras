# APPLICATION LOAD BALANCER SETUP

# NOTE:
# HTTP listener only.
# HTTPS/ACM is intentionally excluded for dev scope.
# ACM + HTTPS listener would be added later as future improvement.

# APPLICATION LOAD BALANCER
resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]
}

# HTTP LISTENER
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_svc.arn
  }
}

# USER SERVICE LISTENER RULE
resource "aws_lb_listener_rule" "user_svc" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_svc.arn
  }

  condition {
    path_pattern {
      # ADDED: /actuator/* so health checks reach the correct service
      values = ["/users*", "/users/*", "/health"]
    }
  }
}

# PRODUCT SERVICE LISTENER RULE
resource "aws_lb_listener_rule" "product_svc" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.product_svc.arn
  }

  condition {
    path_pattern {
      # ADDED: Actuator paths for product service
      values = ["/products*", "/products/*", "/health"]
    }
  }
}

# ALB TARGET GROUPS
# Each ECS service needs its own target group.
# Target type MUST be "ip" for Fargate.

resource "aws_lb_target_group" "frontend_svc" {
  name        = "${var.project_name}-frontend-svc-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "user_svc" {
  name        = "${var.project_name}-user-svc-tg"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
    port                = "8081"
  }
}

resource "aws_lb_target_group" "product_svc" {
  name        = "${var.project_name}-product-svc-tg"
  port        = 8082
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
    port                = "8082"
  }
}