# Image Builder Role
resource "aws_iam_role" "image_builder" {
  name = "golden-image-builder-role"

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
    Name        = "golden-image-builder-role"
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

# S3 read access for golden image bucket (security agent RPMs)
resource "aws_iam_role_policy" "image_builder_s3" {
  name = "golden-image-builder-s3"
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
        Resource = [
          "arn:aws:s3:::${var.golden_image_bucket}",
          "arn:aws:s3:::${var.golden_image_bucket}/*"
        ]
      }
    ]
  })
}

# Image Builder Instance Profile
resource "aws_iam_instance_profile" "image_builder" {
  name = "golden-image-builder-profile"
  role = aws_iam_role.image_builder.name

  tags = {
    Name        = "golden-image-builder-profile"
    Environment = var.environment
  }
}
