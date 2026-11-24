variable "vpc_id" {
  description = "ID de la VPC donde se creará el Security Group"
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