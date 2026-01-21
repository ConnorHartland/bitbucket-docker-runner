# Data source to get the latest AMI built by Image Builder
# Only queried when deploy_ec2_instance = true
data "aws_ami" "bitbucket_runner" {
  count = var.deploy_ec2_instance ? 1 : 0

  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["bitbucket-runner-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:CreatedBy"
    values = ["EC2ImageBuilder"]
  }
}

# User data script with conditional security agent registration
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Get IMDSv2 token (required for AL2023)
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

    # Set hostname
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    hostnamectl set-hostname "bitbucket-runner-$${INSTANCE_ID}"

    # Get region from instance metadata
    REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

    # Get Bitbucket credentials from SSM Parameter Store
    ACCOUNT_UUID=$(aws ssm get-parameter --name "/bitbucket-runners/account-uuid" --with-decryption --query "Parameter.Value" --output text --region "$REGION")
    RUNNERS_JSON=$(aws ssm get-parameter --name "/bitbucket-runners/runners" --with-decryption --query "Parameter.Value" --output text --region "$REGION")

    ${var.enable_wazuh_agent ? <<-WAZUH
    # Register Wazuh agent
    WAZUH_TOKEN=$(aws ssm get-parameter --name "/bitbucket-runners/wazuh-token" --with-decryption --query "Parameter.Value" --output text --region "$REGION")
    WAZUH_MANAGER=$(aws ssm get-parameter --name "/bitbucket-runners/wazuh-manager" --query "Parameter.Value" --output text --region "$REGION")
    /var/ossec/bin/agent-auth -m "$WAZUH_MANAGER" -P "$WAZUH_TOKEN"
    systemctl restart wazuh-agent
    WAZUH
  : "# Wazuh agent disabled"}

    ${var.enable_falcon_sensor ? <<-FALCON
    # Register Falcon sensor
    FALCON_CID=$(aws ssm get-parameter --name "/bitbucket-runners/falcon-cid" --with-decryption --query "Parameter.Value" --output text --region "$REGION")
    /opt/CrowdStrike/falconctl -s --cid="$FALCON_CID"
    systemctl restart falcon-sensor
    FALCON
: "# Falcon sensor disabled"}

    # Start Docker
    systemctl start docker

    ${var.enable_nftables ? "# Start nftables\nsystemctl start nftables" : "# nftables disabled"}

    # Generate docker-compose.yml header
    cat > /opt/bitbucket-runners/docker-compose.yml << 'COMPOSE'
    version: '3.8'
    services:
    COMPOSE

    # Add each runner to docker-compose.yml
    INDEX=1
    RUNNER_COUNT=$(echo "$RUNNERS_JSON" | jq 'length')
    for i in $(seq 0 $((RUNNER_COUNT - 1))); do
      RUNNER_UUID=$(echo "$RUNNERS_JSON" | jq -r ".[$i].uuid")
      OAUTH_CLIENT_ID=$(echo "$RUNNERS_JSON" | jq -r ".[$i].oauth_client_id")
      OAUTH_CLIENT_SECRET=$(echo "$RUNNERS_JSON" | jq -r ".[$i].oauth_client_secret")

      cat >> /opt/bitbucket-runners/docker-compose.yml << RUNNER
      runner-$${INDEX}:
        image: docker-public.packages.atlassian.com/sox/atlassian/bitbucket-pipelines-runner
        restart: unless-stopped
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
          - /var/lib/docker/containers:/var/lib/docker/containers:ro
          - /tmp:/tmp
        environment:
          - ACCOUNT_UUID=$${ACCOUNT_UUID}
          - RUNNER_UUID=$${RUNNER_UUID}
          - OAUTH_CLIENT_ID=$${OAUTH_CLIENT_ID}
          - OAUTH_CLIENT_SECRET=$${OAUTH_CLIENT_SECRET}
          - RUNTIME_PREREQUISITES_ENABLED=true
          - WORKING_DIRECTORY=/tmp
    RUNNER
      INDEX=$((INDEX + 1))
    done

    # Start runners
    cd /opt/bitbucket-runners
    docker-compose up -d
  EOF
}

# EC2 Instance running Bitbucket runners
# Only created when deploy_ec2_instance = true (after AMI is built)
resource "aws_instance" "bitbucket_runner" {
  count = var.deploy_ec2_instance ? 1 : 0

  ami                    = data.aws_ami.bitbucket_runner[0].id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.ec2_instance.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance.name

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(local.user_data)

  tags = {
    Name        = "bitbucket-runner-instance"
    Environment = var.environment
  }

  # Don't recreate if user data changes - can apply changes via SSM
  lifecycle {
    ignore_changes = [user_data, ami]
  }
}
