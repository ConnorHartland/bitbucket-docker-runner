# Image Builder Role
resource "aws_iam_role" "image_builder" {
  name = "bitbucket-runners-image-builder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "bitbucket-runners-image-builder-role"
    Environment = var.environment
  }
}

# EC2 Instance Profile for Image Builder managed policy
resource "aws_iam_role_policy_attachment" "image_builder_ec2" {
  role       = aws_iam_role.image_builder.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

# Image Builder needs SSM for running components
resource "aws_iam_role_policy_attachment" "image_builder_ssm" {
  role       = aws_iam_role.image_builder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Build list of S3 buckets that need access
locals {
  s3_buckets = compact([
    var.enable_crowdstrike && var.falcon_sensor_bucket != "" ? var.falcon_sensor_bucket : "",
    var.enable_nessus && var.nessus_agent_bucket != "" ? var.nessus_agent_bucket : "",
    var.enable_firewall && var.firewall_config_bucket != "" ? var.firewall_config_bucket : ""
  ])

  s3_resources = flatten([
    for bucket in local.s3_buckets : [
      "arn:aws:s3:::${bucket}",
      "arn:aws:s3:::${bucket}/*"
    ]
  ])

  needs_s3_access = length(local.s3_buckets) > 0
}

# Custom policy for S3 read access (conditional - only if any S3 buckets are needed)
resource "aws_iam_role_policy" "image_builder_s3" {
  count = local.needs_s3_access ? 1 : 0

  name = "bitbucket-runners-image-builder-s3"
  role = aws_iam_role.image_builder.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = local.s3_resources
      }
    ]
  })
}

# Image Builder Instance Profile
resource "aws_iam_instance_profile" "image_builder" {
  name = "bitbucket-runners-image-builder-profile"
  role = aws_iam_role.image_builder.name

  tags = {
    Name        = "bitbucket-runners-image-builder-profile"
    Environment = var.environment
  }
}
