# =========================================================
# NETWORK OUTPUTS
# =========================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.network.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.network.private_subnet_id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.network.internet_gateway_id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.network.public_route_table_id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = module.network.private_route_table_id
}

# =========================================================
# SECURITY OUTPUTS
# =========================================================

output "security_group_id" {
  description = "ID of the security group"
  value       = module.security.security_group_id
}

# =========================================================
# AMI OUTPUTS
# =========================================================

output "ubuntu_ami_id" {
  description = "ID of the latest Ubuntu 24.04 LTS AMI"
  value       = module.compute.ubuntu_ami_id
}

# =========================================================
# COMPUTE OUTPUTS
# =========================================================

output "ec2_instance_id" {
  description = "ID of the DevSecOps EC2 instance"
  value       = module.compute.instance_id
}

output "ec2_public_ip" {
  description = "Public IPv4 address of the DevSecOps EC2 instance"
  value       = module.compute.public_ip
}

output "ec2_private_ip" {
  description = "Private IPv4 address of the DevSecOps EC2 instance"
  value       = module.compute.private_ip
}

output "ec2_iam_role_name" {
  description = "IAM Role attached to the EC2 instance"
  value       = module.compute.iam_role_name
}

# =========================================================
# ADVANCED TERRAFORM OUTPUTS
# =========================================================

output "uppercase_servers" {
  description = "Servidores transformados a mayusculas mediante una expresion for"
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
  description = "Tipo de instancia seleccionado mediante una expresion condicional"
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

# SECURITY PRACTICE
# Sensitive outputs

output "example_sensitive_value" {
  description = "ejemplo de output sensible"
  value       = var.example_sensitive_value
  sensitive   = true

}