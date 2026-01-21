output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "security_group_id" {
  description = "ID of the EC2 instance security group"
  value       = aws_security_group.ec2_instance.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  value       = aws_kms_key.bitbucket_runner.arn
}

output "kms_key_id" {
  description = "ID of the KMS key for encryption"
  value       = aws_kms_key.bitbucket_runner.key_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = var.vpc_cidr
}
