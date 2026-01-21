# SSM Parameters for Bitbucket Runners
# These are created with placeholder values - update them via AWS Console or CLI before launching the instance

resource "aws_ssm_parameter" "account_uuid" {
  name        = "/bitbucket-runners/account-uuid"
  description = "Bitbucket workspace UUID (including curly braces)"
  type        = "SecureString"
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
  value       = jsonencode([{ uuid = "PLACEHOLDER", oauth_client_id = "PLACEHOLDER", oauth_client_secret = "PLACEHOLDER" }])

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name        = "bitbucket-runners-config"
    Environment = var.environment
  }
}

# Wazuh parameters (conditional)
resource "aws_ssm_parameter" "wazuh_token" {
  count = var.enable_wazuh_agent ? 1 : 0

  name        = "/bitbucket-runners/wazuh-token"
  description = "Wazuh agent registration token"
  type        = "SecureString"
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
  count = var.enable_wazuh_agent ? 1 : 0

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

# Falcon parameter (conditional)
resource "aws_ssm_parameter" "falcon_cid" {
  count = var.enable_falcon_sensor ? 1 : 0

  name        = "/bitbucket-runners/falcon-cid"
  description = "CrowdStrike Falcon CID"
  type        = "SecureString"
  value       = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name        = "bitbucket-runners-falcon-cid"
    Environment = var.environment
  }
}
