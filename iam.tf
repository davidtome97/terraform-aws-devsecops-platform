# EC2 IAM ROLE
resource "aws_iam_role" "ec2_ssm" {
  name = "${local.name_prefix}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${local.name_prefix}-ec2-ssm-role"
    Project = var.project_name
  }
}

# SSM POLICY ATTACHMENT
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role = aws_iam_role.ec2_ssm.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}

#EC2 INSTANCE PROFILE
resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${local.name_prefix}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name

  tags = {
    Name    = "${local.name_prefix}-ec2-ssm-profile"
    Project = var.project_name
  }
}

