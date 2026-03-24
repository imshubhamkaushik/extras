resource "aws_iam_role" "jenkins_ec2_role" {
  name = "${var.name}-jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# DEV NOTE: AdministratorAccess is intentionally used here for simplicity in a dev/learning environment. 
# Jenkins needs to push to ECR, manage EKS, apply Terraform (which creates IAM roles, EKS, RDS, etc.), and read Secrets Manager.
# Scoping all of that precisely is complex for a dev project.

resource "aws_iam_role_policy_attachment" "jenkins_admin" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# For production, replace the above with the policy below.

# PRODUCTION-READY scoped policy (commented out — replace the above for prod)

# data "aws_iam_policy_document" "jenkins_scoped" {
#   statement {
#     sid    = "ECRAuth"
#     effect = "Allow"
#     actions = ["ecr:GetAuthorizationToken"]
#     resources = ["*"]
#   }
#   statement {
#     sid    = "ECRPush"
#     effect = "Allow"
#     actions = [
#       "ecr:BatchCheckLayerAvailability",
#       "ecr:PutImage",
#       "ecr:InitiateLayerUpload",
#       "ecr:UploadLayerPart",
#       "ecr:CompleteLayerUpload",
#     ]
#     resources = ["arn:aws:ecr:*:*:repository/*"]
#   }
#   statement {
#     sid    = "EKSDescribe"
#     effect = "Allow"
#     actions = ["eks:DescribeCluster"]
#     resources = ["*"]
#   }
#   statement {
#     sid    = "SecretsRead"
#     effect = "Allow"
#     actions = ["secretsmanager:GetSecretValue"]
#     resources = ["arn:aws:secretsmanager:*:*:secret:catalogix/*"]
#   }
#   statement {
#     sid    = "TerraformState"
#     effect = "Allow"
#     actions = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
#     resources = [
#       "arn:aws:s3:::catalogix-tfstate",
#       "arn:aws:s3:::catalogix-tfstate/*",
#     ]
#   }
#   statement {
#     sid    = "TerraformStateLock"
#     effect = "Allow"
#     actions = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
#     resources = ["arn:aws:dynamodb:*:*:table/catalogix-tfstate-lock"]
#   }
# }
#
# resource "aws_iam_policy" "jenkins_scoped" {
#   name   = "${var.name}-jenkins-scoped-policy"
#   policy = data.aws_iam_policy_document.jenkins_scoped.json
# }
#
# resource "aws_iam_role_policy_attachment" "jenkins_scoped" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = aws_iam_policy.jenkins_scoped.arn
# }

resource "aws_iam_role" "sonar_ec2_role" {
  name = "${var.name}-sonar-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
    # No policy attachments - SonarQube needs no AWS permission
  })
}