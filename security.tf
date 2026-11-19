# SECURITY GROUPS
resource "aws_security_group" "terraform_lab" {
  name        = "${local.name_prefix}-sg"
  description = "security group for terraform learning project"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${local.name_prefix}-sg"
    Project = var.project_name
  }
}