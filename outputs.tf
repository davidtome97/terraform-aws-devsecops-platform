# NETWORK OUTPUTS

output "vpc_id" {

  description = "ID of the VPC"

  value = aws_vpc.main.id

}

output "public_subnet_id" {

  description = "ID of the public subnet"

  value = aws_subnet.public.id

}

output "private_subnet_id" {

  description = "ID of the private subnet"

  value = aws_subnet.private.id

}

output "internet_gateway_id" {

  description = "ID of the Internet Gateway"

  value = aws_internet_gateway.main.id

}

output "public_route_table_id" {

  description = "ID of the public route table"

  value = aws_route_table.public.id

}

output "private_route_table_id" {

  description = "ID of the private route table"

  value = aws_route_table.private.id

}

output "security_group_id" {

  description = "ID of the security group"

  value = aws_security_group.terraform_lab.id

}

output "ubuntu_ami_id" {
  description = "ID of the latest Ubuntu 24.04 LTS AMI"
  value       = data.aws_ami.ubuntu.id

}

# COMPUTE OUTPUTS

output "ec2_instance_id" {
  description = "ID of the DevSecOps EC2 instance"
  value       = aws_instance.devsecops.id
}

output "ec2_public_ip" {
  description = "Public IPv4 address of the DevSecOps EC2 instance"
  value       = aws_instance.devsecops.public_ip
}

output "ec2_private_ip" {
  description = "Private IPv4 address of the DevSecOps EC2 instance"
  value       = aws_instance.devsecops.private_ip
}

output "ec2_iam_role_name" {
  description = "IAM Role attached to the EC2 instance"
  value       = aws_iam_role.ec2_ssm.name
}


output "uppercase_servers" {
  description = "servidores transformados a mayusculas mediante una expresion for"
  value       = local.uppercase_servers
}

output "filtered_servers" {
  description = "Servidores filtrados y transformados"
  value       = local.filtered_servers
}

output "server_map" {
  description = "Mapa generado mediante una expresión for"
  value       = local.server_map
}

output "example_instance_type" {
  description = "tipo de instancia seleccionado mediante una expresion condicional"
  value       = local.example_instance_type
}

output "function_list" {
  value = local.function_list
}

output "function_tags" {
  value = local.function_tags
}

output "function_instance_type" {
  value = local.function_instance_type
}

output "function_unique_services" {
  value = local.function_unique_services
}

output "function_optional_value" {
  value = local.function_optional_value
}

output "function_name" {
  value = local.function_name
}