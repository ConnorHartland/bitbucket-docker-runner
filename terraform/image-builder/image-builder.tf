# EC2 Image Builder for Bitbucket Runner Golden AMI

# =============================================================================
# Core Components (always included)
# =============================================================================

resource "aws_imagebuilder_component" "system_update" {
  name        = "bitbucket-runners-system-update"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Update system packages"

  data = file("${path.module}/components/system-update.yaml")

  tags = {
    Name        = "bitbucket-runners-system-update"
    Environment = var.environment
  }
}

resource "aws_imagebuilder_component" "install_linuxtools" {
  name        = "bitbucket-runners-install-linuxtools"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install common Linux tools and utilities"

  data = file("${path.module}/components/install-linuxtools.yaml")

  tags = {
    Name        = "bitbucket-runners-install-linuxtools"
    Environment = var.environment
  }
}

resource "aws_imagebuilder_component" "install_docker" {
  name        = "bitbucket-runners-install-docker"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install Docker, docker-compose, and configure daemon security"

  data = file("${path.module}/components/install-docker.yaml")

  tags = {
    Name        = "bitbucket-runners-install-docker"
    Environment = var.environment
  }
}

resource "aws_imagebuilder_component" "install_cloudwatch_agent" {
  name        = "bitbucket-runners-install-cloudwatch-agent"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install and configure CloudWatch agent for monitoring and logging"

  data = file("${path.module}/components/install-cloudwatch-agent.yaml")

  tags = {
    Name        = "bitbucket-runners-install-cloudwatch-agent"
    Environment = var.environment
  }
}

# =============================================================================
# Optional Components (conditionally included)
# =============================================================================

# Node.js
resource "aws_imagebuilder_component" "install_nodejs" {
  count = var.enable_nodejs ? 1 : 0

  name        = "bitbucket-runners-install-nodejs"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install Node.js and npm"

  data = file("${path.module}/components/install-nodejs.yaml")

  tags = {
    Name        = "bitbucket-runners-install-nodejs"
    Environment = var.environment
  }
}

# Firewall (nftables from S3)
resource "aws_imagebuilder_component" "firewall_update" {
  count = var.enable_firewall ? 1 : 0

  name        = "bitbucket-runners-firewall-update"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install nftables and download configuration from S3"

  data = templatefile("${path.module}/components/firewall-update.yaml", {
    firewall_config_bucket = var.firewall_config_bucket
    firewall_config_key    = var.firewall_config_key
  })

  tags = {
    Name        = "bitbucket-runners-firewall-update"
    Environment = var.environment
  }
}

# CrowdStrike Falcon
resource "aws_imagebuilder_component" "install_crowdstrike" {
  count = var.enable_crowdstrike ? 1 : 0

  name        = "bitbucket-runners-install-crowdstrike"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install CrowdStrike Falcon sensor from S3"

  data = templatefile("${path.module}/components/install-crowdstrike.yaml", {
    falcon_sensor_bucket = var.falcon_sensor_bucket
    falcon_sensor_key    = var.falcon_sensor_key
  })

  tags = {
    Name        = "bitbucket-runners-install-crowdstrike"
    Environment = var.environment
  }
}

# Wazuh
resource "aws_imagebuilder_component" "install_wazuh" {
  count = var.enable_wazuh ? 1 : 0

  name        = "bitbucket-runners-install-wazuh"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install Wazuh agent (registration happens at boot)"

  data = file("${path.module}/components/install-wazuh.yaml")

  tags = {
    Name        = "bitbucket-runners-install-wazuh"
    Environment = var.environment
  }
}

# Nessus
resource "aws_imagebuilder_component" "install_nessus" {
  count = var.enable_nessus ? 1 : 0

  name        = "bitbucket-runners-install-nessus"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install Nessus agent from S3"

  data = templatefile("${path.module}/components/install-nessus.yaml", {
    nessus_agent_bucket = var.nessus_agent_bucket
    nessus_agent_key    = var.nessus_agent_key
  })

  tags = {
    Name        = "bitbucket-runners-install-nessus"
    Environment = var.environment
  }
}

# New Relic
resource "aws_imagebuilder_component" "install_newrelic" {
  count = var.enable_newrelic ? 1 : 0

  name        = "bitbucket-runners-install-newrelic"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install New Relic infrastructure agent"

  data = file("${path.module}/components/install-newrelic.yaml")

  tags = {
    Name        = "bitbucket-runners-install-newrelic"
    Environment = var.environment
  }
}

# =============================================================================
# Component ARNs List
# =============================================================================

locals {
  component_arns = concat(
    # Core components (always included, in order)
    [aws_imagebuilder_component.system_update.arn],
    [aws_imagebuilder_component.install_linuxtools.arn],
    [aws_imagebuilder_component.install_docker.arn],
    [aws_imagebuilder_component.install_cloudwatch_agent.arn],

    # Optional components
    var.enable_nodejs ? [aws_imagebuilder_component.install_nodejs[0].arn] : [],
    var.enable_firewall ? [aws_imagebuilder_component.firewall_update[0].arn] : [],
    var.enable_crowdstrike ? [aws_imagebuilder_component.install_crowdstrike[0].arn] : [],
    var.enable_wazuh ? [aws_imagebuilder_component.install_wazuh[0].arn] : [],
    var.enable_nessus ? [aws_imagebuilder_component.install_nessus[0].arn] : [],
    var.enable_newrelic ? [aws_imagebuilder_component.install_newrelic[0].arn] : []
  )
}

# =============================================================================
# Image Recipe
# =============================================================================

resource "aws_imagebuilder_image_recipe" "bitbucket_runner" {
  name         = "bitbucket-runners-recipe"
  parent_image = data.aws_ssm_parameter.al2023_ami.value
  version      = "1.0.0"

  block_device_mapping {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
    }
  }

  dynamic "component" {
    for_each = local.component_arns
    content {
      component_arn = component.value
    }
  }

  tags = {
    Name        = "bitbucket-runners-recipe"
    Environment = var.environment
  }
}

# =============================================================================
# Infrastructure Configuration
# =============================================================================

resource "aws_imagebuilder_infrastructure_configuration" "bitbucket_runner" {
  name                          = "bitbucket-runners-infrastructure"
  instance_profile_name         = aws_iam_instance_profile.image_builder.name
  instance_types                = ["t3.medium"]
  subnet_id                     = data.terraform_remote_state.infrastructure.outputs.private_subnet_ids[0]
  security_group_ids            = [data.terraform_remote_state.infrastructure.outputs.security_group_id]
  terminate_instance_on_failure = true

  tags = {
    Name        = "bitbucket-runners-infrastructure"
    Environment = var.environment
  }
}

# =============================================================================
# Distribution Configuration
# =============================================================================

resource "aws_imagebuilder_distribution_configuration" "bitbucket_runner" {
  name = "bitbucket-runners-distribution"

  distribution {
    region = var.aws_region

    ami_distribution_configuration {
      name = "bitbucket-runner-{{ imagebuilder:buildDate }}"

      ami_tags = {
        Name        = "bitbucket-runner-ami"
        Environment = var.environment
        CreatedBy   = "EC2ImageBuilder"
      }
    }
  }

  tags = {
    Name        = "bitbucket-runners-distribution"
    Environment = var.environment
  }
}

# =============================================================================
# Image Pipeline
# =============================================================================

resource "aws_imagebuilder_image_pipeline" "bitbucket_runner" {
  name                             = "bitbucket-runners-pipeline"
  image_recipe_arn                 = aws_imagebuilder_image_recipe.bitbucket_runner.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.bitbucket_runner.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.bitbucket_runner.arn

  # Manual trigger - no schedule
  # To build: aws imagebuilder start-image-pipeline-execution --image-pipeline-arn <arn>

  tags = {
    Name        = "bitbucket-runners-pipeline"
    Environment = var.environment
  }
}
