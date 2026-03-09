output "public_ip" {
    description = "Public IP of the instance — used in env/dev/outputs.tf"
    value       = aws_instance.this.public_ip
}