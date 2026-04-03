# terraform-backend/main.tf

# This Terraform configuration sets up the S3 bucket and DynamoDB table for Terraform state management.
resource "aws_s3_bucket" "tf_state" {
  bucket = "catalogix-terraform-state-dev"
  force_destroy = false # Protects against accidental deletion of the bucket and its contents

  tags = {
    Project     = "catalogix"
    Environment = "dev"
  }
}

# Configure S3 bucket access control
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for the bucket
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for using Customer Managed Key (CMK) for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      kms_master_key_id = aws_kms_alias.tf_state_alias.arn
    }
  }
}

# KMS Key for Encryption
resource "aws_kms_key" "tf_state_key" {
  description             = "KMS key for encrypting Terraform state in S3"
  deletion_window_in_days = 30

  tags = {
    Project     = "catalogix"
    Environment = "dev"
  }
}

resource "aws_kms_alias" "tf_state_alias" {
  name          = "alias/${var.project_name}-tf-state-dev"
  target_key_id = aws_kms_key.tf_state_key.id
}