# ============================================================
# TERRAFORM INTERMEDIO / AVANZADO
# ============================================================

# ============================================================
# COUNT
# ============================================================

variable "example_servers" {
  description = "Lista de servidores utilizada para practicar count"
  type        = list(string)

  default = [
    "web",
    "api",
    "worker"
  ]
}

resource "terraform_data" "count_example" {
  count = length(var.example_servers)

  input = {
    name  = var.example_servers[count.index]
    index = count.index
  }
}

# ============================================================
# FOR_EACH
# ============================================================

variable "example_services" {
  description = "Conjunto de servicios utilizado para practicar for_each"
  type        = set(string)

  default = [
    "web",
    "api",
    "worker"
  ]
}

resource "terraform_data" "for_each_example" {
  for_each = var.example_services

  input = {
    name = each.value
  }
}

# ============================================================
# DYNAMIC BLOCKS
# ============================================================

resource "aws_security_group" "dynamic_example" {
  name        = "${local.name_prefix}-dynamic-example"
  description = "Security group utilizado para practicar dynamic blocks"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.example_ingress_rules

    content {
      description = "Example rule: ${ingress.key}"
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  tags = {
    Name = "${local.name_prefix}-dynamic-example"
  }
}

# ============================================================
# DEPENDENCIES / DEPENDS_ON
# ============================================================

resource "terraform_data" "dependency_database" {
  input = {
    name = "database"
  }
}

resource "terraform_data" "dependency_application" {
  input = {
    name = "application"
  }

  # Terraform no puede inferir esta dependencia a partir de
  # referencias entre atributos, por lo que la declaramos
  # explícitamente.
  depends_on = [
    terraform_data.dependency_database
  ]
}

# ============================================================
# LIFECYCLE
# ============================================================

# Los siguientes bloques se mantienen comentados como ejemplos
# de los experimentos realizados durante la sección 05.
#
# No forman parte de la infraestructura final del laboratorio.

# ------------------------------------------------------------
# create_before_destroy
# ------------------------------------------------------------
#
# En una sustitución normal Terraform puede destruir primero el
# recurso antiguo y crear después el nuevo.
#
# create_before_destroy invierte ese comportamiento cuando es
# posible: primero crea el reemplazo y después elimina el antiguo.
#
# resource "terraform_data" "lifecycle_create_before_destroy" {
#   input = {
#     name = "lifecycle-demo"
#   }
#
#   triggers_replace = [
#     "v2"
#   ]
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# ------------------------------------------------------------
# prevent_destroy
# ------------------------------------------------------------
#
# Evita que Terraform ejecute una operación que implique destruir
# esta instancia mientras la regla esté presente en la configuración.
#
# Importante:
# eliminar completamente el resource de la configuración también
# elimina esta regla, por lo que prevent_destroy no constituye una
# protección permanente del recurso en AWS.
#
# resource "terraform_data" "lifecycle_prevent_destroy" {
#   input = {
#     name = "protected-demo"
#   }
#
#   lifecycle {
#     prevent_destroy = true
#   }
# }

# ------------------------------------------------------------
# ignore_changes
# ------------------------------------------------------------
#
# Terraform utiliza el atributo durante la creación, pero después
# ignora cambios en dicho atributo al calcular actualizaciones.
#
# Es útil cuando una propiedad es gestionada parcialmente por otro
# sistema externo.
#
# resource "terraform_data" "lifecycle_ignore_changes" {
#   input = {
#     name = "lifecycle-demo"
#   }
#
#   lifecycle {
#     ignore_changes = [
#       input
#     ]
#   }
# }

# ------------------------------------------------------------
# replace_triggered_by
# ------------------------------------------------------------
#
# Permite reemplazar un recurso cuando cambia otro recurso
# relacionado.
#
# Durante la práctica comprobamos que application puede ser
# reemplazado aunque application_version solamente cambie in-place.
#
# resource "terraform_data" "application_version" {
#   input = "v2"
# }
#
# resource "terraform_data" "application" {
#   input = "my-application"
#
#   lifecycle {
#     replace_triggered_by = [
#       terraform_data.application_version
#     ]
#   }
# }

# ============================================================
# MOVED BLOCKS
# ============================================================

# Durante la práctica partimos de:
#
# resource "terraform_data" "old_name" {
#   input = "moved-demo"
# }
#
# Después renombramos el recurso a:
#
# resource "terraform_data" "new_name" {
#   input = "moved-demo"
# }
#
# Sin un moved block Terraform interpretaba el cambio como:
#
#   old_name -> destroy
#   new_name -> create
#
# Declarando el movimiento:
#
# moved {
#   from = terraform_data.old_name
#   to   = terraform_data.new_name
# }
#
# Terraform conserva la identidad del objeto y actualiza su
# dirección en el state sin destruirlo y volverlo a crear.
#
# En nuestro experimento obtuvimos:
#
# Plan: 0 to add, 0 to change, 0 to destroy.

# ============================================================
# IMPORT
# ============================================================

# Importamos una VPC existente de AWS al state utilizando:
#
# terraform import aws_vpc.main vpc-XXXXXXXX
#
# El import NO crea el recurso en AWS. Asocia un objeto remoto
# existente con una dirección de Terraform.
#
# Después del import siempre debemos comprobar:
#
# terraform plan
#
# para reconciliar configuración, state e infraestructura real.
#
# También puede utilizarse un import block declarativo:
#
# import {
#   to = aws_vpc.main
#   id = "vpc-XXXXXXXX"
# }
#
# Los import blocks pueden almacenarse en Git y formar parte del
# flujo plan/apply.

# ============================================================
# STATE RM
# ============================================================

# Durante la práctica ejecutamos:
#
# terraform state rm aws_vpc.main
#
# Esto elimina la asociación del recurso del STATE.
#
# NO elimina la VPC real de AWS.
#
# Antes:
#
#   AWS   -> existe
#   State -> gestionada
#
# Después:
#
#   AWS   -> sigue existiendo
#   State -> ya no gestionada

# ============================================================
# FORZAR REEMPLAZO (-replace)
# ============================================================

# Si Terraform considera que un recurso no necesita cambios pero
# queremos reemplazarlo intencionadamente, podemos utilizar:
#
# terraform plan -replace=terraform_data.example
#
# Un flujo más controlado sería:
#
# terraform plan \
#   -replace=terraform_data.example \
#   -out=tfplan
#
# terraform apply tfplan
#
# -replace es el enfoque actual recomendado frente al antiguo
# workflow basado en terraform taint.

# ============================================================
# TAINT (LEGACY)
# ============================================================

# terraform taint RESOURCE_ADDRESS
#
# Marca una instancia del state como "tainted", haciendo que
# Terraform planifique su reemplazo posteriormente.
#
# Es importante conocerlo para Terraform Associate y para trabajar
# con proyectos antiguos, aunque actualmente se prefiere utilizar:
#
# terraform apply -replace=RESOURCE_ADDRESS
#
# o planificar primero con:
#
# terraform plan -replace=RESOURCE_ADDRESS