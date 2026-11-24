output "security_group_id" {
  description = "ID del Security Group creado por el módulo"
  value       = aws_security_group.terraform_lab.id
}