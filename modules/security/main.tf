# checkov:skip=CKV2_AWS_5:False positive - this security group is attached to the EC2 instance through the compute module
resource "aws_security_group" "terraform_lab" {
  name        = "${var.name_prefix}-sg"
  description = "security group for terraform learning project"
  vpc_id      = var.vpc_id

  egress = [{
    description = "Allow HTTPS outbound traffic"

    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
    }, {
    description = "Allow HTTP outbound traffic for package repositories"

    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
    }

  ]

  tags = {
    Name    = "${var.name_prefix}-sg"
    Project = var.project_name
  }
}