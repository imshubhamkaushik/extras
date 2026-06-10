# ecr/main.tf

# ECR Repositories
# frontend-svc
resource "aws_ecr_repository" "frontend_svc" {
  name                 = "${var.project_name}-frontend-svc"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Not suitable for production
  image_scanning_configuration {
    scan_on_push = true
  }
}

# user-svc
resource "aws_ecr_repository" "user_svc" {
  name                 = "${var.project_name}-user-svc"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Not suitable for production
  image_scanning_configuration {
    scan_on_push = true
  }
}

# product-svc
resource "aws_ecr_repository" "product_svc" {
  name                 = "${var.project_name}-product-svc"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Not suitable for production
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Policy for Frontend Service (frontend-svc)
resource "aws_ecr_lifecycle_policy" "frontend_cleanup" {
  repository = aws_ecr_repository.frontend_svc.name
  policy     = local.ecr_policy
}

# Policy for User Service (user-svc)
resource "aws_ecr_lifecycle_policy" "user_cleanup" {
  repository = aws_ecr_repository.user_svc.name
  policy     = local.ecr_policy
}

# Policy for Product Service (product-svc)
resource "aws_ecr_lifecycle_policy" "product_cleanup" {
  repository = aws_ecr_repository.product_svc.name
  policy     = local.ecr_policy
}

# Define the policy once in a local to avoid copy-pasting the JSON 3 times
locals {
  ecr_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
