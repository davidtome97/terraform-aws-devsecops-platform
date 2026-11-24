resource "aws_security_group" "terraform_lab" {
  name        = "${var.name_prefix}-sg"
  description = "security group for terraform learning project"
  vpc_id      = var.vpc_id

  egress {
    description = "allow all outbound traffic"

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.name_prefix}-sg"
    Project = var.project_name
  }
}