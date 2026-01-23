output "instance_id" {
  description = "ID of the Bitbucket runner EC2 instance"
  value       = var.deploy_ec2_instance ? aws_instance.bitbucket_runner[0].id : null
}

output "instance_private_ip" {
  description = "Private IP of the Bitbucket runner EC2 instance"
  value       = var.deploy_ec2_instance ? aws_instance.bitbucket_runner[0].private_ip : null
}

output "golden_ami_id" {
  description = "ID of the Golden AMI used by the instance"
  value       = var.deploy_ec2_instance ? data.aws_ami.golden_image[0].id : null
}

output "ssm_parameter_paths" {
  description = "SSM Parameter Store paths that need to be updated with actual values"
  value = {
    account_uuid  = aws_ssm_parameter.account_uuid.name
    runners       = aws_ssm_parameter.runners.name
    wazuh_token   = aws_ssm_parameter.wazuh_token.name
    wazuh_manager = aws_ssm_parameter.wazuh_manager.name
    falcon_cid    = aws_ssm_parameter.falcon_cid.name
  }
}

output "security_agents" {
  description = "Security agents always installed and registered at boot"
  value = {
    crowdstrike = true
    wazuh       = true
    nessus      = true
  }
}

output "optional_features" {
  description = "Optional features"
  value = {
    firewall = var.enable_firewall
  }
}
