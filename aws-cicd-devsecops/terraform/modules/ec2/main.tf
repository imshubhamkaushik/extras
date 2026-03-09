resource "aws_iam_role" "ec2_role" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "this" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.profile.name
  vpc_security_group_ids = [var.security_group_id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted = true
  }

  tags = {
    Name = var.name
    Project = var.project_tag
    Role = var.role
  }
}