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
                <<-EOT
cat > /etc/nftables.conf << 'EOF'
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    # Rate limit for logging to prevent log spam
    set ratelimit_log {
        type ipv4_addr
        flags timeout
        timeout 1m
    }

    chain input {
        type filter hook input priority 0; policy drop;

        # Drop invalid packets early
        ct state invalid drop

        # Allow established/related connections
        ct state established,related accept

        # Allow loopback
        iif lo accept

        # Rate limit ICMP (5 per second with burst of 10)
        ip protocol icmp limit rate 5/second burst 10 packets accept
        ip6 nexthdr icmpv6 limit rate 5/second burst 10 packets accept

        # Drop ICMP flood
        ip protocol icmp drop
        ip6 nexthdr icmpv6 drop

        # Allow SSH (if needed for debugging via SSM port forwarding)
        # tcp dport 22 accept

        # Rate-limited logging for dropped packets (max 5 per minute per source IP)
        ip saddr @ratelimit_log drop
        log prefix "nftables-input-drop: " limit rate 5/minute add @ratelimit_log { ip saddr timeout 1m }
        drop
    }

    chain forward {
        type filter hook forward priority 0; policy drop;

        # Drop invalid packets
        ct state invalid drop

        # Allow Docker container traffic
        ct state established,related accept

        # Allow traffic from Docker containers
        iifname "docker*" accept
        oifname "docker*" accept

        # Log and drop anything else
        log prefix "nftables-forward-drop: " limit rate 5/minute drop
    }

    chain output {
        type filter hook output priority 0; policy accept;

        # Drop invalid packets
        ct state invalid drop

        # Allow established connections
        ct state established,related accept

        # Allow loopback
        oif lo accept

        # Allow DNS (UDP and TCP)
        udp dport 53 accept
        tcp dport 53 accept

        # Allow HTTPS
        tcp dport 443 accept

        # Allow HTTP
        tcp dport 80 accept

        # Allow SSH (git operations)
        tcp dport 22 accept

        # Allow NTP
        udp dport 123 accept

        # Log unusual outbound connections (rate-limited)
        log prefix "nftables-output-unusual: " limit rate 5/minute accept
    }
}
EOF
                EOT
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

# Component: Configure Docker daemon security hardening (always included)
resource "aws_imagebuilder_component" "configure_docker_security" {
  name        = "bitbucket-runners-configure-docker-security"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Configure Docker daemon with security hardening settings"

  data = yamlencode({
    schemaVersion = 1.0
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "CreateDockerDaemonConfig"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "mkdir -p /etc/docker",
                <<-EOT
cat > /etc/docker/daemon.json << 'EOF'
{
  "icc": false,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "default-ulimits": {
    "nofile": { "Name": "nofile", "Hard": 65536, "Soft": 65536 },
    "nproc": { "Name": "nproc", "Hard": 4096, "Soft": 4096 }
  }
}
EOF
                EOT
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name        = "bitbucket-runners-configure-docker-security"
    Environment = var.environment
  }
}

# Component: Install and configure CloudWatch agent (always included)
resource "aws_imagebuilder_component" "install_cloudwatch_agent" {
  name        = "bitbucket-runners-install-cloudwatch-agent"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Install and configure CloudWatch agent for monitoring and logging"

  data = yamlencode({
    schemaVersion = 1.0
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "InstallCloudWatchAgent"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "dnf install -y amazon-cloudwatch-agent"
              ]
            }
          },
          {
            name   = "ConfigureCloudWatchAgent"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",
                <<-EOT
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/bitbucket-runners/ec2",
            "log_stream_name": "{instance_id}/messages",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "/bitbucket-runners/security",
            "log_stream_name": "{instance_id}/secure",
            "retention_in_days": 90
          },
          {
            "file_path": "/var/log/docker.log",
            "log_group_name": "/bitbucket-runners/docker",
            "log_stream_name": "{instance_id}/docker",
            "retention_in_days": 30
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "BitbucketRunners",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60,
        "resources": ["*"],
        "totalcpu": true
      },
      "disk": {
        "measurement": ["disk_used_percent", "disk_free", "disk_used"],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      },
      "mem": {
        "measurement": ["mem_used_percent", "mem_available", "mem_used"],
        "metrics_collection_interval": 60
      },
      "net": {
        "measurement": ["net_bytes_recv", "net_bytes_sent"],
        "metrics_collection_interval": 60,
        "resources": ["eth0"]
      }
    },
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}"
    }
  }
}
EOF
                EOT
              ]
            }
          },
          {
            name   = "EnableCloudWatchAgent"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "systemctl enable amazon-cloudwatch-agent"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name        = "bitbucket-runners-install-cloudwatch-agent"
    Environment = var.environment
  }
}

# Build local list of component ARNs based on enabled features
locals {
  component_arns = concat(
    [aws_imagebuilder_component.install_docker.arn],
    [aws_imagebuilder_component.configure_docker_security.arn],
    [aws_imagebuilder_component.install_cloudwatch_agent.arn],
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
