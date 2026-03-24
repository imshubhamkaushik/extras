# ecs-cluster/main.tf

# ECS CLUSTER
# ECS cluster is the logical grouping for services and tasks.
# With Fargate, there are NO EC2 instances or node management.

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}.cluster_name"
}
