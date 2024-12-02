
# IAM Role for EC2 to access ECR
resource "aws_iam_role" "ec2_ecr_role" {
  name = "EC2_ECR_Access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "ec2-ecr-role"
  }
}

# IAM Policy for the role to access ECR
resource "aws_iam_role_policy" "ec2_ecr_policy" {
  name = "EC2_ECR_Access_Policy"
  role = aws_iam_role.ec2_ecr_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ],
        Resource = "*"
      },
    ]
  })
}

# IAM Instance Profile for the role to access ECR
resource "aws_iam_instance_profile" "ec2_ecr_instance_profile" {
  name = "EC2_ECR_Access"
  role = aws_iam_role.ec2_ecr_role.name

  tags = {
    Name = "ec2-ecr-instance-profile"
  }
}
