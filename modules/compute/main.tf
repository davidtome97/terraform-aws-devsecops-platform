# =========================================================
# AMI
# =========================================================

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =========================================================
# IAM ROLE FOR EC2 / SSM
# =========================================================

resource "aws_iam_role" "ec2_ssm" {
  name = "${var.name_prefix}-ec2-ssm-role"

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
    Name    = "${var.name_prefix}-ec2-ssm-role"
    Project = var.project_name
  }
}

# =========================================================
# SSM POLICY ATTACHMENT
# =========================================================

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role = aws_iam_role.ec2_ssm.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# =========================================================
# EC2 INSTANCE PROFILE
# =========================================================

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${var.name_prefix}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name

  tags = {
    Name    = "${var.name_prefix}-ec2-ssm-profile"
    Project = var.project_name
  }
}

# =========================================================
# EC2 INSTANCE
# =========================================================

resource "aws_instance" "devsecops" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id                   = var.subnet_id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    var.security_group_id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name

  user_data = file("${path.module}/user-data.sh")

  tags = {
    Name    = "${var.name_prefix}-ec2"
    Project = var.project_name
  }
}