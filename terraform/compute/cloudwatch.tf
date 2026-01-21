# CloudWatch Log Groups for Bitbucket Runners
# Encrypted with customer-managed KMS key

resource "aws_cloudwatch_log_group" "ec2" {
  name              = "/bitbucket-runners/ec2"
  retention_in_days = 30
  kms_key_id        = data.terraform_remote_state.infrastructure.outputs.kms_key_arn

  tags = {
    Name        = "bitbucket-runners-ec2-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "docker" {
  name              = "/bitbucket-runners/docker"
  retention_in_days = 30
  kms_key_id        = data.terraform_remote_state.infrastructure.outputs.kms_key_arn

  tags = {
    Name        = "bitbucket-runners-docker-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "security" {
  name              = "/bitbucket-runners/security"
  retention_in_days = 90
  kms_key_id        = data.terraform_remote_state.infrastructure.outputs.kms_key_arn

  tags = {
    Name        = "bitbucket-runners-security-logs"
    Environment = var.environment
  }
}

# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "alerts" {
  name = "bitbucket-runners-alerts"

  tags = {
    Name        = "bitbucket-runners-alerts"
    Environment = var.environment
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.deploy_ec2_instance ? 1 : 0

  alarm_name          = "bitbucket-runners-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "CPU utilization > 85% for 15 minutes"

  dimensions = {
    InstanceId = aws_instance.bitbucket_runner[0].id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "bitbucket-runners-cpu-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  count = var.deploy_ec2_instance ? 1 : 0

  alarm_name          = "bitbucket-runners-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 instance status check failed"

  dimensions = {
    InstanceId = aws_instance.bitbucket_runner[0].id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "bitbucket-runners-status-alarm"
    Environment = var.environment
  }
}

# Custom CloudWatch Alarms using CloudWatch Agent metrics
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count = var.deploy_ec2_instance ? 1 : 0

  alarm_name          = "bitbucket-runners-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "mem_used_percent"
  namespace           = "BitbucketRunners"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "Memory utilization > 90% for 15 minutes"

  dimensions = {
    InstanceId = aws_instance.bitbucket_runner[0].id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "bitbucket-runners-memory-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_high" {
  count = var.deploy_ec2_instance ? 1 : 0

  alarm_name          = "bitbucket-runners-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "BitbucketRunners"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Disk utilization > 80%"

  dimensions = {
    InstanceId = aws_instance.bitbucket_runner[0].id
    path       = "/"
    fstype     = "xfs"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "bitbucket-runners-disk-alarm"
    Environment = var.environment
  }
}
