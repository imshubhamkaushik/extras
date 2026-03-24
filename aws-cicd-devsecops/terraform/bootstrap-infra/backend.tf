terraform {
  backend "s3" {
    bucket         = "catalogix-tf-state"
    key            = "bootstrap/terraform.tfstate"
    region         = var.aws_region
    encrypt = true
    use_lockfile = true
  }
}

