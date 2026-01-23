# Customer-managed KMS key for Bitbucket runner encryption
# Used for EBS volumes, CloudWatch Logs, and SSM Parameter Store

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "bitbucket_runner" {
  description             = "KMS key for Bitbucket runner encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsEncryption"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      },
      {
        Sid    = "AllowEC2ServiceForEBS"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
            "kms:ViaService"    = "ec2.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "bitbucket-runners-kms-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "bitbucket_runner" {
  name          = "alias/bitbucket-runners"
  target_key_id = aws_kms_key.bitbucket_runner.key_id
}
