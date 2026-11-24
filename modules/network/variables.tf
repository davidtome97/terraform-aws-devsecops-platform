variable "vpc_cidr" {
  description = "CIDR block de la VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block de la subnet pública"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block de la subnet privada"
  type        = string
}

variable "availability_zone" {
  description = "Availability Zone donde se crearán las subnets"
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