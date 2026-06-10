// Backend configuration for Dev environment
terraform {
  backend "s3" {
    bucket       = "catalogix-terraform-state-dev"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
