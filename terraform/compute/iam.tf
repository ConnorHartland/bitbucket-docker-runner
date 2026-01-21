# EC2 Instance Role for Bitbucket Runner Instance
resource "aws_iam_role" "ec2_instance" {
  name = "bitbucket-runners-ec2-instance-role"

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
    Name        = "bitbucket-runners-ec2-instance-role"
    Environment = var.environment
  }
}

# SSM Managed Instance Core for SSM agent and Run Command
resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom policy for SSM Parameter Store read access
resource "aws_iam_role_policy" "ec2_ssm_parameters" {
  name = "bitbucket-runners-ssm-parameters"
  role = aws_iam_role.ec2_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/bitbucket-runners/*"
      }
    ]
  })
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2_instance" {
  name = "bitbucket-runners-ec2-instance-profile"
  role = aws_iam_role.ec2_instance.name

  tags = {
    Name        = "bitbucket-runners-ec2-instance-profile"
    Environment = var.environment
  }
}
