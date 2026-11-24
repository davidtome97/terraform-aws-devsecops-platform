variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
}

variable "subnet_id" {
  description = "ID de la subnet donde se desplegará la instancia EC2"
  type        = string
}

variable "security_group_id" {
  description = "ID del Security Group asociado a la instancia EC2"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto utilizado para etiquetar los recursos"
  type        = string
}

variable "name_prefix" {
  description = "Prefijo utilizado para nombrar los recursos"
  type        = string
}