resource "aws_iam_instance_profile" "profile" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "jenkins_catalogix" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[*].id
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.profile.name
  vpc_security_group_ids = [var.jenkins_sg]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "Jenkins Server - Catalogix"
    Project = var.project_tag
    Role = var.role
  }
}

resource "aws_instance" "sonarqube_catalogix" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[*].id
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.profile.name
  vpc_security_group_ids = [var.sonarqube_sg]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "SonarQube Server - Catalogix" 
    Project = var.project_tag
    Role = var.role
  }
}