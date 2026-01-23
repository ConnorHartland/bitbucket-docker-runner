# SSM Parameters for Bitbucket Runners
# These are created with placeholder values - update them via AWS Console or CLI before launching the instance

resource "aws_ssm_parameter" "account_uuid" {
  name        = "/bitbucket-runners/account-uuid"
  description = "Bitbucket workspace UUID (including curly braces)"
  type        = "SecureString"
  key_id      = data.terraform_remote_state.image_builder.outputs.kms_key_id
  value       = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name        = "bitbucket-runners-account-uuid"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "runners" {
  name        = "/bitbucket-runners/runners"
  description = "JSON array of runner configurations with uuid, oauth_client_id, and oauth_client_secret"
  type        = "SecureString"
  key_id      = data.terraform_remote_state.image_builder.outputs.kms_key_id
  value       = jsonencode([{ uuid = "PLACEHOLDER", oauth_client_id = "PLACEHOLDER", oauth_client_secret = "PLACEHOLDER" }])

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name        = "bitbucket-runners-config"
    Environment = var.environment
  }
}

# Wazuh parameters (always created)
resource "aws_ssm_parameter" "wazuh_token" {
  name        = "/bitbucket-runners/wazuh-token"
  description = "Wazuh agent registration token"
  type        = "SecureString"
  key_id      = data.terraform_remote_state.image_builder.outputs.kms_key_id
  value       = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name        = "bitbucket-runners-wazuh-token"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "wazuh_manager" {
  name        = "/bitbucket-runners/wazuh-manager"
  description = "Wazuh manager IP or hostname"
  type        = "String"
  value       = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name        = "bitbucket-runners-wazuh-manager"
    Environment = var.environment
  }
}

# CrowdStrike Falcon parameter (always created)
resource "aws_ssm_parameter" "falcon_cid" {
  name        = "/bitbucket-runners/falcon-cid"
  description = "CrowdStrike Falcon CID"
  type        = "SecureString"
  key_id      = data.terraform_remote_state.image_builder.outputs.kms_key_id
  value       = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name        = "bitbucket-runners-falcon-cid"
    Environment = var.environment
  }
}
