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

output "instance_id" {
  description = "ID of the Bitbucket runner EC2 instance"
  value       = var.deploy_ec2_instance ? aws_instance.bitbucket_runner[0].id : null
}

output "instance_private_ip" {
  description = "Private IP of the Bitbucket runner EC2 instance"
  value       = var.deploy_ec2_instance ? aws_instance.bitbucket_runner[0].private_ip : null
}

output "image_builder_pipeline_arn" {
  description = "ARN of the EC2 Image Builder pipeline"
  value       = aws_imagebuilder_image_pipeline.bitbucket_runner.arn
}

output "golden_ami_id" {
  description = "ID of the Golden AMI used by the instance"
  value       = var.deploy_ec2_instance ? data.aws_ami.bitbucket_runner[0].id : null
}

output "ssm_parameter_paths" {
  description = "SSM Parameter Store paths that need to be updated with actual values"
  value = merge(
    {
      account_uuid = aws_ssm_parameter.account_uuid.name
      runners      = aws_ssm_parameter.runners.name
    },
    var.enable_wazuh_agent ? {
      wazuh_token   = aws_ssm_parameter.wazuh_token[0].name
      wazuh_manager = aws_ssm_parameter.wazuh_manager[0].name
    } : {},
    var.enable_falcon_sensor ? {
      falcon_cid = aws_ssm_parameter.falcon_cid[0].name
    } : {}
  )
}

output "enabled_features" {
  description = "Which optional features are enabled"
  value = {
    wazuh_agent   = var.enable_wazuh_agent
    falcon_sensor = var.enable_falcon_sensor
    nftables      = var.enable_nftables
  }
}
