#NETWORK VARIABLES
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability Zone for the subnets"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string

}

# GENERAL VARIABLES

variable "project_name" {
  description = "Name of the project"
  type        = string
}

# CONDITIONAL EXPRESSIONS

variable "example_environment" {
  description = "entorno utilizado para practicar expresiones condicionales"
  type        = string
  default     = "dev"
}

# ============================================================
# DYNAMIC BLOCKS
# ============================================================

variable "example_ingress_rules" {
  description = "Reglas de ejemplo utilizadas para practicar dynamic blocks"

  type = map(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = {
    http = {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }

    https = {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }

    application = {
      port        = 8080
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  }
}