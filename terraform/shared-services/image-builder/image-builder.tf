# EC2 Image Builder for Golden Image AMI

# =============================================================================
# Core Components (always included)
# =============================================================================

resource "aws_imagebuilder_component" "system_update" {
  name        = "golden-image-system-update"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Update system packages"

  data = file("./components/system-update.yaml")

  tags = {
    Name        = "golden-image-system-update"
    Environment = var.environment
  }
}

resource "aws_imagebuilder_component" "cis_cloudinit_fix" {
  name        = "golden-image-cis-cloudinit-fix"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Fix CIS L2 hardening to allow cloud-init script execution"

  data = file("./components/cis-cloudinit-fix.yaml")

  tags = {
    Name        = "golden-image-cis-cloudinit-fix"
    Environment = var.environment
  }
}

resource "aws_imagebuilder_component" "install_linuxtools" {
  name        = "golden-image-install-linuxtools"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install common Linux tools and utilities"

  data = file("./components/install-linuxtools.yaml")

  tags = {
    Name        = "golden-image-install-linuxtools"
    Environment = var.environment
  }
}

resource "aws_imagebuilder_component" "install_cloudwatch_agent" {
  name        = "golden-image-install-cloudwatch-agent"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install and configure CloudWatch agent for monitoring and logging"

  data = file("./components/install-cloudwatch-agent.yaml")

  tags = {
    Name        = "golden-image-install-cloudwatch-agent"
    Environment = var.environment
  }
}

# =============================================================================
# Security Components (always included)
# =============================================================================

resource "aws_imagebuilder_component" "install_crowdstrike" {
  name        = "golden-image-install-crowdstrike"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install CrowdStrike Falcon sensor from S3"

  data = templatefile("./components/install-crowdstrike.yaml", {
    golden_image_bucket = var.golden_image_bucket
  })

  tags = {
    Name        = "golden-image-install-crowdstrike"
    Environment = var.environment
  }
}

resource "aws_imagebuilder_component" "install_wazuh" {
  name        = "golden-image-install-wazuh"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install Wazuh agent from S3 (registration happens at boot)"

  data = templatefile("./components/install-wazuh.yaml", {
    golden_image_bucket = var.golden_image_bucket
  })

  tags = {
    Name        = "golden-image-install-wazuh"
    Environment = var.environment
  }
}

resource "aws_imagebuilder_component" "install_nessus" {
  name        = "golden-image-install-nessus"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install Nessus agent from S3"

  data = templatefile("./components/install-nessus.yaml", {
    golden_image_bucket = var.golden_image_bucket
  })

  tags = {
    Name        = "golden-image-install-nessus"
    Environment = var.environment
  }
}

# Firewall (nftables from S3) - always included
resource "aws_imagebuilder_component" "firewall_update" {
  name        = "golden-image-firewall-update"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install nftables and download configuration from S3"

  data = templatefile("./components/firewall-update.yaml", {
    golden_image_bucket = var.golden_image_bucket
  })

  tags = {
    Name        = "golden-image-firewall-update"
    Environment = var.environment
  }
}

# =============================================================================
# Optional Components (conditionally included)
# =============================================================================

# Docker
resource "aws_imagebuilder_component" "install_docker" {
  count = var.enable_docker ? 1 : 0

  name        = "golden-image-install-docker"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install Docker, docker-compose, and configure daemon security"

  data = file("./components/install-docker.yaml")

  tags = {
    Name        = "golden-image-install-docker"
    Environment = var.environment
  }
}

# Node.js
resource "aws_imagebuilder_component" "install_nodejs" {
  count = var.enable_nodejs ? 1 : 0

  name        = "golden-image-install-nodejs"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install Node.js and npm"

  data = file("./components/install-nodejs.yaml")

  tags = {
    Name        = "golden-image-install-nodejs"
    Environment = var.environment
  }
}

# New Relic
resource "aws_imagebuilder_component" "install_newrelic" {
  count = var.enable_newrelic ? 1 : 0

  name        = "golden-image-install-newrelic"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install New Relic infrastructure agent"

  data = file("./components/install-newrelic.yaml")

  tags = {
    Name        = "golden-image-install-newrelic"
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
    [aws_imagebuilder_component.cis_cloudinit_fix.arn],
    [aws_imagebuilder_component.install_linuxtools.arn],
    [aws_imagebuilder_component.install_cloudwatch_agent.arn],

    # Security components (always included)
    [aws_imagebuilder_component.install_crowdstrike.arn],
    [aws_imagebuilder_component.install_wazuh.arn],
    [aws_imagebuilder_component.install_nessus.arn],
    [aws_imagebuilder_component.firewall_update.arn],

    # Optional components
    var.enable_docker ? [aws_imagebuilder_component.install_docker[0].arn] : [],
    var.enable_nodejs ? [aws_imagebuilder_component.install_nodejs[0].arn] : [],
    var.enable_newrelic ? [aws_imagebuilder_component.install_newrelic[0].arn] : []
  )
}

# =============================================================================
# Image Recipe
# =============================================================================

resource "aws_imagebuilder_image_recipe" "golden_image" {
  name              = "golden-image-${var.image_name}-recipe"
  parent_image      = data.aws_ami.cis_al2023_l2.id
  version           = "1.0.0"
  working_directory = "/var/local"

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
    Name        = "golden-image-${var.image_name}-recipe"
    Environment = var.environment
  }
}

# =============================================================================
# Infrastructure Configuration
# =============================================================================

resource "aws_imagebuilder_infrastructure_configuration" "golden_image" {
  name                          = "golden-image-${var.image_name}-infrastructure"
  instance_profile_name         = aws_iam_instance_profile.image_builder.name
  instance_types                = ["t3.medium"]
  subnet_id                     = data.aws_subnets.private.ids[0]
  security_group_ids            = [aws_security_group.image_builder.id]
  terminate_instance_on_failure = true

  tags = {
    Name        = "golden-image-${var.image_name}-infrastructure"
    Environment = var.environment
  }
}

# =============================================================================
# Distribution Configuration
# =============================================================================

resource "aws_imagebuilder_distribution_configuration" "golden_image" {
  name = "golden-image-${var.image_name}-distribution"

  distribution {
    region = var.aws_region

    ami_distribution_configuration {
      name = "CIS_L2_AL2023_${var.image_name}_Golden_Image-{{ imagebuilder:buildDate }}"

      ami_tags = {
        Name        = "CIS_L2_AL2023_${var.image_name}_Golden_Image"
        ImageType   = var.image_name
        Environment = var.environment
        CreatedBy   = "EC2ImageBuilder"
      }
    }
  }

  tags = {
    Name        = "golden-image-${var.image_name}-distribution"
    Environment = var.environment
  }
}

# =============================================================================
# Image Pipeline
# =============================================================================

resource "aws_imagebuilder_image_pipeline" "golden_image" {
  name                             = "golden-image-${var.image_name}-pipeline"
  image_recipe_arn                 = aws_imagebuilder_image_recipe.golden_image.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.golden_image.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.golden_image.arn

  # Manual trigger - no schedule
  # To build: aws imagebuilder start-image-pipeline-execution --image-pipeline-arn <arn>

  tags = {
    Name        = "golden-image-${var.image_name}-pipeline"
    Environment = var.environment
  }
}
