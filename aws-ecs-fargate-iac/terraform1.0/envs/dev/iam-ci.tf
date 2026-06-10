# # Not used currently, but can be used in the future for GitHub Actions OIDC-based authentication to AWS.
# resource "aws_iam_openid_connect_provider" "github" {
#   url = "https://token.actions.githubusercontent.com"

#   client_id_list = ["sts.amazonaws.com"]

#   thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
# }

# resource "aws_iam_role" "github_actions" {
#   name = "${var.project_name}-github-actions"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.github.arn
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringLike = {
#             "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
#           }
#         }
#       },
#       {
#         # Allow you to assume the role locally (SSO/IAM)
#         Sid    = "AllowSSOUsers"
#         Effect = "Allow"
#         Principal = {
#           # Using the root ARN allows any IAM user/SSO role in your 
#           # account with AssumeRole permissions to use this role.
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "github_actions" {
#   role = aws_iam_role.github_actions.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = ["ecr:*"]
#         Resource = "*"
#       },
#       {
#         Effect   = "Allow"
#         Action   = [
#           "ecs:RegisterTaskDefinition",
#           "ecs:UpdateService",
#           "ecs:DescribeServices",
#           "ecs:DescribeTaskDefinition"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect   = "Allow"
#         Action   = "iam:PassRole"
#         Resource = [
#           aws_iam_role.ecs_execution.arn,
#           aws_iam_role.ecs_task.arn
#         ]
#       }
#     ]
#   })
# }
