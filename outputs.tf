output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.runner.name
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group for runner logs"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret for Bitbucket OAuth"
  value       = aws_secretsmanager_secret.bitbucket_oauth.arn
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}
