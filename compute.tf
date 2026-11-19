#AMI

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

#EC2 INSTANCE
resource "aws_instance" "devsecops" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.terraform_lab.id
  ]
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name
  user_data            = file("${path.module}/user-data.sh")
  tags = {
    Name    = "${local.name_prefix}-ec2"
    Project = var.project_name
  }
}