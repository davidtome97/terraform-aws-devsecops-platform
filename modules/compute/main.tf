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

# IAM TRUST POLICY

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }

}


# =========================================================
# IAM ROLE FOR EC2 / SSM
# =========================================================

resource "aws_iam_role" "ec2_ssm" {
  name = "${var.name_prefix}-ec2-ssm-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

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
  # checkov:skip=CKV_AWS_88:Public IP intentionally required for this low-cost lab. No inbound access is allowed and administration is performed through AWS SSM.


  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  ebs_optimized = true

  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  monitoring                  = true



  vpc_security_group_ids = [
    var.security_group_id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  user_data = file("${path.module}/user-data.sh")

  lifecycle {
    precondition {
      condition     = length(var.security_group_id) > 0
      error_message = "la instancia EC2 debe tener un Security Group asignado."
    }
    postcondition {
      condition     = self.metadata_options[0].http_tokens == "required"
      error_message = "la instancia EC2 debe requerir IMDSv2"
    }
  }

  tags = {
    Name    = "${var.name_prefix}-ec2"
    Project = var.project_name
  }
}

