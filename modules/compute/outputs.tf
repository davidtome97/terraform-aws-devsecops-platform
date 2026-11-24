output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.devsecops.id
}

output "public_ip" {
  description = "IPv4 pública de la instancia EC2"
  value       = aws_instance.devsecops.public_ip
}

output "private_ip" {
  description = "IPv4 privada de la instancia EC2"
  value       = aws_instance.devsecops.private_ip
}

output "iam_role_name" {
  description = "Nombre del IAM Role asociado a la instancia EC2"
  value       = aws_iam_role.ec2_ssm.name
}

output "ubuntu_ami_id" {
  description = "ID de la AMI Ubuntu utilizada por la instancia EC2"
  value       = data.aws_ami.ubuntu.id
}