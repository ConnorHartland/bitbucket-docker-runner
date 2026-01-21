# EC2 Image Builder for Bitbucket Runner Golden AMI

# Component: Install Docker and docker-compose (always included)
resource "aws_imagebuilder_component" "install_docker" {
  name        = "bitbucket-runners-install-docker"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install Docker and docker-compose on Amazon Linux 2023"

  data = yamlencode({
    schemaVersion = 1.0
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "InstallDocker"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "dnf install -y docker jq",
                "systemctl enable docker",
                "usermod -aG docker ec2-user"
              ]
            }
          },
          {
            name   = "InstallDockerCompose"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
                "chmod +x /usr/local/bin/docker-compose",
                "ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose"
              ]
            }
          },
          {
            name   = "CreateRunnersDirectory"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "mkdir -p /opt/bitbucket-runners",
                "chown ec2-user:ec2-user /opt/bitbucket-runners"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name        = "bitbucket-runners-install-docker"
    Environment = var.environment
  }
}

# Component: Install Wazuh agent (conditional)
resource "aws_imagebuilder_component" "install_wazuh" {
  count = var.enable_wazuh_agent ? 1 : 0

  name        = "bitbucket-runners-install-wazuh"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install Wazuh agent on Amazon Linux 2023 (registration happens at boot)"

  data = yamlencode({
    schemaVersion = 1.0
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "AddWazuhRepo"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH",
                "cat > /etc/yum.repos.d/wazuh.repo << 'EOF'\n[wazuh]\ngpgcheck=1\ngpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://packages.wazuh.com/4.x/yum/\nprotect=1\nEOF"
              ]
            }
          },
          {
            name   = "InstallWazuhAgent"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "dnf install -y wazuh-agent",
                "systemctl daemon-reload",
                "systemctl enable wazuh-agent"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name        = "bitbucket-runners-install-wazuh"
    Environment = var.environment
  }
}

# Component: Install Falcon sensor (conditional)
resource "aws_imagebuilder_component" "install_falcon" {
  count = var.enable_falcon_sensor ? 1 : 0

  name        = "bitbucket-runners-install-falcon"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install CrowdStrike Falcon sensor from S3 (registration happens at boot)"

  data = yamlencode({
    schemaVersion = 1.0
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "DownloadFalconSensor"
            action = "S3Download"
            inputs = [
              {
                source      = "s3://${var.falcon_sensor_s3_bucket}/${var.falcon_sensor_s3_key}"
                destination = "/tmp/falcon-sensor.rpm"
              }
            ]
          },
          {
            name   = "InstallFalconSensor"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "dnf install -y /tmp/falcon-sensor.rpm",
                "rm -f /tmp/falcon-sensor.rpm",
                "systemctl enable falcon-sensor"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name        = "bitbucket-runners-install-falcon"
    Environment = var.environment
  }
}

# Component: Configure nftables (conditional)
resource "aws_imagebuilder_component" "configure_nftables" {
  count = var.enable_nftables ? 1 : 0

  name        = "bitbucket-runners-configure-nftables"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install and configure nftables on Amazon Linux 2023"

  data = yamlencode({
    schemaVersion = 1.0
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "InstallNftables"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "dnf install -y nftables"
              ]
            }
          },
          {
            name   = "ConfigureNftables"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "cat > /etc/nftables.conf << 'EOF'\n#!/usr/sbin/nft -f\n\nflush ruleset\n\ntable inet filter {\n    chain input {\n        type filter hook input priority 0; policy drop;\n        \n        # Allow established/related connections\n        ct state established,related accept\n        \n        # Allow loopback\n        iif lo accept\n        \n        # Allow ICMP\n        ip protocol icmp accept\n        ip6 nexthdr icmpv6 accept\n        \n        # Allow SSH (if needed for debugging)\n        # tcp dport 22 accept\n        \n        # Drop everything else\n        log prefix \"nftables-drop: \" drop\n    }\n    \n    chain forward {\n        type filter hook forward priority 0; policy drop;\n        \n        # Allow Docker container traffic\n        ct state established,related accept\n        \n        # Allow traffic from Docker containers\n        iifname \"docker*\" accept\n        oifname \"docker*\" accept\n    }\n    \n    chain output {\n        type filter hook output priority 0; policy accept;\n    }\n}\nEOF"
              ]
            }
          },
          {
            name   = "EnableNftables"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "systemctl enable nftables"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name        = "bitbucket-runners-configure-nftables"
    Environment = var.environment
  }
}

# Build local list of component ARNs based on enabled features
locals {
  component_arns = concat(
    [aws_imagebuilder_component.install_docker.arn],
    var.enable_wazuh_agent ? [aws_imagebuilder_component.install_wazuh[0].arn] : [],
    var.enable_falcon_sensor ? [aws_imagebuilder_component.install_falcon[0].arn] : [],
    var.enable_nftables ? [aws_imagebuilder_component.configure_nftables[0].arn] : []
  )
}

# Image Recipe - combines enabled components
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

# Infrastructure Configuration
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

# Distribution Configuration
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

# Image Pipeline
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
