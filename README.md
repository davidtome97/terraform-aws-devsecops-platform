# Plataforma DevSecOps en AWS con Terraform

Proyecto práctico para aprender **Terraform sobre AWS** construyendo una
infraestructura real de forma progresiva, entendiendo qué hace cada
componente antes de avanzar al siguiente.

El objetivo no es únicamente desplegar infraestructura, sino aprender un
flujo de trabajo profesional con **Infrastructure as Code (IaC)** y
reforzar conceptos importantes para **HashiCorp Terraform Associate**.

**Flujo de trabajo:** entender → implementar → formatear → validar →
planificar → revisar → aplicar → verificar → documentar → versionar.

> 🚧 **Estado actual:** Fundamentos + State/Backend remoto +
> Networking + Compute/EC2 + Terraform intermedio/avanzado completados.
> 🔐 EC2 administrada mediante **AWS Systems Manager Session Manager**,
> sin SSH público ni puerto 22 abierto.
> ☁️ El State del proyecto principal está almacenado remotamente en
> **Amazon S3**, con cifrado, versionado y locking.
> 🧠 Se han practicado conceptos avanzados como `count`, `for_each`,
> expresiones `for`, `dynamic`, `lifecycle`, `import`, `moved` y
> reemplazo controlado de recursos.

---

# 🎯 Objetivos del proyecto

- Aprender Terraform de forma práctica.
- Preparar conceptos relevantes para Terraform Associate.
- Construir infraestructura AWS desde cero.
- Comprender Infrastructure as Code y configuración declarativa.
- Trabajar con providers, resources y data sources.
- Utilizar variables, locals y outputs.
- Evitar valores hardcodeados.
- Entender dependencias implícitas y el Dependency Graph.
- Comprender Terraform State y Remote State.
- Configurar un backend remoto en Amazon S3.
- Comprender State Locking, versionado y cifrado.
- Diseñar networking básico en AWS.
- Desplegar Compute mediante EC2.
- Administrar EC2 mediante AWS Systems Manager.
- Automatizar configuración mediante User Data.
- Trabajar con `count`, `for_each` y expresiones `for`.
- Utilizar expresiones condicionales y funciones.
- Generar bloques anidados mediante `dynamic`.
- Comprender dependencias explícitas con `depends_on`.
- Controlar ciclos de vida mediante `lifecycle`.
- Importar infraestructura existente.
- Refactorizar direcciones mediante `moved`.
- Forzar reemplazos de forma controlada.
- Validar cambios antes de modificar AWS.
- Verificar infraestructura mediante AWS CLI.
- Diagnosticar problemas reales de infraestructura.
- Versionar Infrastructure as Code mediante Git.
- Evolucionar hacia una plataforma DevOps / DevSecOps y CI/CD.

---

# 🧰 Tecnologías

| Tecnología | Uso |
|---|---|
| Terraform | Infrastructure as Code |
| AWS | Cloud Provider |
| Amazon VPC | Networking |
| Amazon EC2 | Compute |
| Amazon S3 | Remote Terraform State |
| AWS IAM | Roles y permisos |
| AWS Systems Manager | Administración remota segura |
| AWS CLI | Verificación y diagnóstico |
| Ubuntu Server 24.04 LTS | Sistema operativo EC2 |
| Git | Control de versiones |
| GitHub | Repositorio remoto |

**Región AWS:** `eu-west-1`
**Availability Zone actual:** `eu-west-1a`

---

# 🗺️ Roadmap

```text
00 — Plan general y roadmap

01 — Fundamentos de Terraform
     ├── init / fmt / validate / plan / apply / destroy
     ├── providers
     ├── resources / data sources
     ├── variables / tfvars
     ├── locals / outputs
     ├── funciones y expresiones
     └── dependencias

02 — State y Backend remoto
     ├── terraform.tfstate
     ├── State local / remoto
     ├── Backend S3
     ├── Bootstrap
     ├── Migración del State
     ├── Cifrado
     ├── Versionado
     ├── State Locking
     ├── state list / show / mv / rm
     ├── import
     └── HCP Terraform

03 — AWS Networking
     ├── VPC / CIDR
     ├── Subnets públicas y privadas
     ├── Internet Gateway
     ├── Route Tables / Routes
     ├── Associations
     └── Security Groups

04 — Compute / EC2
     ├── AMI Data Source
     ├── EC2
     ├── IAM
     ├── Instance Profile
     ├── User Data
     └── Systems Manager / Session Manager

05 — Terraform intermedio / avanzado
     ├── count
     ├── for_each
     ├── for expressions
     ├── conditionals
     ├── functions
     ├── dynamic blocks
     ├── depends_on
     ├── lifecycle
     ├── import / import blocks
     ├── state rm
     ├── moved blocks
     ├── -replace / taint
     └── refactoring seguro

06 — Módulos y estructura profesional
     ├── Root Module / Child Modules
     ├── Inputs / Outputs
     ├── Module Sources
     ├── Terraform Registry
     ├── Versionado
     └── Refactoring

07+ — DevSecOps
     ├── Entornos
     ├── CI/CD
     ├── Security Scanning
     ├── Quality Gates
     ├── Hardened Images
     └── Automatización
```

---

# 📁 Estructura actual

```text
terraform-aws-devsecops-platform/
│
├── backend.tf
├── versions.tf
├── providers.tf
├── variables.tf
├── terraform.tfvars
├── locals.tf
├── network.tf
├── security.tf
├── compute.tf
├── iam.tf
├── advanced.tf
├── user-data.sh
├── outputs.tf
│
├── bootstrap/
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── .terraform.lock.hcl
│
├── README.md
├── .gitignore
└── .terraform.lock.hcl
```

Los archivos locales ignorados por Git pueden existir físicamente aunque
no aparezcan en el repositorio, por ejemplo `terraform.tfvars`,
`terraform.tfstate`, `.terraform/` y sus equivalentes dentro de
`bootstrap/`.

Terraform interpreta todos los archivos `.tf` del mismo directorio como
**una única configuración**.

El nombre y orden de los archivos no determina el orden de creación.
Terraform utiliza su **Dependency Graph**.

---

# 01 — Fundamentos de Terraform

## 01.1 — Organización

Separar archivos por responsabilidad mejora la mantenibilidad:

```text
network.tf   → Networking
security.tf  → Security Groups
compute.tf   → EC2
iam.tf       → IAM
advanced.tf  → Conceptos Terraform avanzados
outputs.tf   → Outputs
backend.tf   → Backend
```

Terraform identifica un recurso por su dirección:

```text
aws_instance.devsecops
```

y no por el fichero donde esté escrito.

### 🧠 ¿Qué aprendimos?

Mover un bloque entre archivos `.tf` dentro del mismo módulo no cambia
por sí solo su dirección.

Terraform determina las dependencias mediante referencias entre objetos.

---

## 01.2 — Provider vs Backend

El **provider** permite comunicarse con una plataforma:

```text
Terraform → AWS Provider → AWS API → AWS
```

El **backend** determina dónde y cómo se almacena el State:

```text
Terraform → Backend → State
```

### 🧠 ¿Qué aprendimos?

```text
Provider → ¿Cómo interactúa Terraform con AWS?
Backend  → ¿Dónde se almacena el State?
```

Son conceptos diferentes.

---

## 01.3 — Resources y Data Sources

Un `resource` representa infraestructura administrada por Terraform:

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}
```

Un `data` consulta información existente:

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
}
```

### 🧠 ¿Qué aprendimos?

```text
resource → crear / modificar / eliminar
data     → consultar
```

Un Data Source también puede aparecer en el State, aunque Terraform no
haya creado el objeto consultado.

---

## 01.4 — Variables

Ejemplo:

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
```

Los valores pueden proceder de:

```text
default
terraform.tfvars
*.auto.tfvars
-var
-var-file
TF_VAR_...
```

### 🧠 ¿Qué aprendimos?

`variables.tf` declara las entradas.

`terraform.tfvars` puede proporcionar sus valores.

---

## 01.5 — Locals

```hcl
locals {
  name_prefix = "terraform-lab"
}
```

```text
var.xxx   → entrada configurable
local.xxx → valor interno reutilizable
```

---

## 01.6 — Outputs

Ejemplo:

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}
```

Consulta:

```bash
terraform output
terraform output ec2_instance_id
terraform output -raw ec2_instance_id
```

Los outputs pueden ser consumidos por usuarios, scripts u otras
configuraciones Terraform.

---

## 01.7 — Comandos básicos

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
terraform output
```

Flujo:

```text
Código
  ↓
terraform fmt
  ↓
terraform validate
  ↓
terraform plan
  ↓
REVISAR
  ↓
terraform apply
```

Símbolos principales:

```text
+     create
~     update in-place
-     destroy
-/+   destroy and create replacement
+/-   create replacement and then destroy
```

---

## 01.8 — Plan guardado

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Esto permite aplicar el plan previamente calculado.

Los archivos de plan no se versionan en Git.

---

## 01.9 — `(known after apply)`

Durante `terraform plan` algunos atributos pueden aparecer como:

```text
(known after apply)
```

Terraform conoce el atributo, pero su valor definitivo todavía no puede
determinarse hasta ejecutar la operación.

No es un error.

---

# 02 — Terraform State y Backend remoto

## 02.1 — ¿Qué es Terraform State?

Terraform necesita relacionar las direcciones de la configuración con
los objetos reales.

```text
CONFIGURACIÓN

aws_instance.devsecops
        │
        ▼
      STATE
        │
        ▼
i-xxxxxxxxxxxxxxxxx
        │
        ▼
      AWS
```

### 🧠 ¿Qué aprendimos?

```text
Configuration → qué queremos
State         → qué objetos gestiona Terraform
Provider      → comunicación con AWS
AWS           → qué existe realmente
```

---

## 02.2 — Comandos de State

```bash
terraform state list
terraform state show aws_instance.devsecops
terraform state show aws_vpc.main
terraform show
```

`state list` muestra las direcciones registradas.

`state show` inspecciona un objeto concreto.

---

## 02.3 — State local

Inicialmente utilizamos:

```text
terraform.tfstate
```

Arquitectura:

```text
Mac
│
├── código .tf
└── terraform.tfstate
        │
        ▼
       AWS
```

Problemas:

- Dependencia de un único ordenador.
- Mala colaboración.
- Riesgo de pérdida.
- Riesgo de modificaciones concurrentes.
- Posible información sensible.

Por ello `*.tfstate` está excluido de Git.

---

## 02.4 — `sensitive = true`

```text
sensitive = true
```

puede ocultar valores en determinadas salidas.

Pero:

```text
sensitive = true ≠ cifrar automáticamente el State
```

Ocultar información y proteger el almacenamiento del State son problemas
diferentes.

---

## 02.5 — Backend remoto

Movimos el State principal a Amazon S3:

```text
Mac / Terraform CLI
        │
        ▼
   Amazon S3
        │
        ▼
dev/terraform.tfstate
        │
        ▼
       AWS
```

Configuración:

```hcl
terraform {
  backend "s3" {
    bucket       = "terraform-aws-devsecops-dt97-state"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-1"
    profile      = "terraform-lab"
    encrypt      = true
    use_lockfile = true
  }
}
```

El backend se procesa durante `terraform init`.

---

## 02.6 — Bootstrap

Para almacenar el State en S3 el bucket debe existir previamente.

Por eso creamos:

```text
bootstrap/
```

Arquitectura:

```text
BOOTSTRAP
   ↓
crea backend S3

PROYECTO PRINCIPAL
   ↓
utiliza backend S3
```

El bootstrap mantiene su propio State independiente.

---

## 02.7 — Recursos del Bootstrap

Creamos:

```text
aws_s3_bucket.terraform_state
aws_s3_bucket_public_access_block.terraform_state
aws_s3_bucket_server_side_encryption_configuration.terraform_state
aws_s3_bucket_versioning.terraform_state
```

Configuramos:

```text
Public Access Block
Encryption
Versioning
```

El State es información crítica y potencialmente sensible.

---

## 02.8 — Migración del State

Ejecutamos:

```bash
terraform init -migrate-state
```

Conceptualmente:

```text
ANTES

Mac
└── terraform.tfstate


MIGRACIÓN
     ↓


DESPUÉS

Amazon S3
└── dev/
    └── terraform.tfstate
```

### 🧠 ¿Qué aprendimos?

No migramos VPC, EC2, IAM ni ningún recurso AWS.

Migramos únicamente el **State**.

---

## 02.9 — S3 Versioning

S3 conserva versiones del objeto:

```text
terraform.tfstate
    │
    ├── Version 1
    ├── Version 2
    ├── Version 3
    └── Version actual
```

```text
Versioning ≠ State Locking
```

---

## 02.10 — State Locking

Configuramos:

```hcl
use_lockfile = true
```

Conceptualmente:

```text
Proceso A
   │
   ▼
adquiere lock 🔒
   │
   ▼
trabaja con State
   │
   ▼
libera lock 🔓
```

Distinción:

```text
Versioning → historial / recuperación
Locking    → concurrencia
Encryption → confidencialidad en reposo
```

---

## 02.11 — `.terraform.lock.hcl`

No debemos confundir:

```text
.terraform.lock.hcl
        │
        └── selecciones de providers

State Lock
        │
        └── concurrencia del State

S3 Versioning
        │
        └── versiones anteriores
```

`.terraform.lock.hcl` normalmente se versiona en Git.

---

## 02.12 — `terraform state mv`

```bash
terraform state mv ORIGEN DESTINO
```

Permite modificar una dirección dentro del State.

```text
aws_instance.devsecops
        │
        ▼
aws_instance.platform
```

No implica necesariamente recrear la instancia AWS.

---

## 02.13 — `terraform state rm`

```bash
terraform state rm DIRECCION
```

Elimina la asociación del State:

```text
ANTES

Terraform State ─────► Recurso AWS


state rm


Terraform State   X   Recurso AWS
                      │
                      └── sigue existiendo
```

```text
state rm ≠ destroy
```

---

## 02.14 — Import

Si existe infraestructura fuera del State podemos asociarla:

```bash
terraform import aws_vpc.main vpc-xxxxxxxx
```

```text
Código
  │
  ├──── import ────► AWS existente
  │
  ▼
State
```

El import no crea el objeto remoto.

---

## 02.15 — Drift

Ejemplo:

```text
Terraform Configuration
t2.micro

AWS real
t3.micro
```

Existe una diferencia entre el estado deseado y la infraestructura real.

Terraform puede detectarla durante refresh/plan.

---

## 02.16 — HCP Terraform vs S3

Nuestro modelo:

```text
Terraform CLI
     │
     ▼
Amazon S3
     │
     ▼
Remote State
```

HCP Terraform puede añadir capacidades de plataforma como ejecución
remota, colaboración, VCS, workspaces, variables y controles
centralizados.

---

# 03 — AWS Networking

## 03.1 — Arquitectura

```text
                              INTERNET
                                  │
                                  ▼
                         Internet Gateway
                                  │
                                  ▼
                        VPC 10.0.0.0/16
                                  │
                 ┌────────────────┴────────────────┐
                 │                                 │
        PUBLIC SUBNET                       PRIVATE SUBNET
         10.0.1.0/24                         10.0.2.0/24
         eu-west-1a                           eu-west-1a
                 │                                 │
      Public Route Table                 Private Route Table
                 │                                 │
       ┌─────────┴─────────┐                       │
       │                   │                       │
10.0.0.0/16 → local   0.0.0.0/0 → IGW      10.0.0.0/16 → local
```

---

## 03.2 — VPC

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${local.name_prefix}-vpc"
    Project = var.project_name
  }
}
```

CIDR:

```text
10.0.0.0/16
```

Utilizamos referencias:

```hcl
aws_vpc.main.id
```

en lugar de hardcodear IDs.

---

## 03.3 — Subnets

```text
Public  → 10.0.1.0/24
Private → 10.0.2.0/24
```

Un `/24` contiene 256 direcciones IPv4.

AWS reserva cinco direcciones por subnet.

Una subnet no es pública simplemente por llamarse `public`.

---

## 03.4 — Internet Gateway

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```

Crear un IGW no convierte automáticamente una subnet en pública:

```text
Subnet
  ↓
Route Table
  ↓
0.0.0.0/0
  ↓
Internet Gateway
```

---

## 03.5 — Route Tables

Public:

```text
10.0.0.0/16 → local
0.0.0.0/0   → IGW
```

Private:

```text
10.0.0.0/16 → local
```

La ruta `local` permite comunicación dentro de la VPC.

---

## 03.6 — Associations

```hcl
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

Crear una Route Table no basta: debemos asociarla con una subnet.

---

## 03.7 — Main Route Table

AWS crea determinados recursos automáticamente, como la Main Route
Table de una VPC.

### 🧠 ¿Qué aprendimos?

No todo lo visible en AWS tiene que haber sido declarado explícitamente
mediante un `resource`.

---

## 03.8 — Security Group

Configuración:

```text
Ingress → ninguno
Egress  → permitido
```

```hcl
resource "aws_security_group" "terraform_lab" {
  name   = "${local.name_prefix}-sg"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

```text
Security Group → stateful
Network ACL    → stateless
```

---

# 04 — Compute / EC2

## 04.1 — Arquitectura

```text
                         INTERNET
                             │
                             ▼
                    Internet Gateway
                             │
                             ▼
                    VPC 10.0.0.0/16
                             │
               ┌─────────────┴─────────────┐
               │                           │
        PUBLIC SUBNET                PRIVATE SUBNET
         10.0.1.0/24                  10.0.2.0/24
               │
               ▼
             EC2
        Ubuntu 24.04 LTS
          t2.micro
               │
        Security Group
      ingress: ninguno
      egress: permitido
               │
               ▼
         Instance Profile
               │
               ▼
           IAM Role
               │
               ▼
 AmazonSSMManagedInstanceCore
               │
               ▼
      AWS Systems Manager
               │
               ▼
        Session Manager
```

---

## 04.2 — AMI mediante Data Source

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

`most_recent = true` permite seleccionar la AMI más reciente que cumpla
los filtros.

---

## 04.3 — `validate` vs `plan`

Aprendimos:

```text
validate correcto ≠ plan garantizado
plan correcto     ≠ apply garantizado
```

`terraform validate` puede comprobar la estructura de una configuración,
pero no garantiza que una API remota acepte posteriormente todos los
valores.

---

## 04.4 — EC2

```hcl
resource "aws_instance" "devsecops" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.terraform_lab.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name

  user_data = file("${path.module}/user-data.sh")

  tags = {
    Name    = "${local.name_prefix}-ec2"
    Project = var.project_name
  }
}
```

Dependencias:

```text
VPC
 ↓
Subnet
 ↓
EC2
```

y:

```text
IAM Role
 ↓
Instance Profile
 ↓
EC2
```

---

## 04.5 — IAM Role

La Trust Policy responde:

```text
¿QUIÉN puede asumir el Role?
```

Las Permissions Policies responden:

```text
¿QUÉ puede hacer?
```

Utilizamos:

```text
sts:AssumeRole
```

para permitir que EC2 asumiera el Role.

---

## 04.6 — `jsonencode()`

```text
Terraform value
      ↓
jsonencode()
      ↓
JSON
```

`jsondecode()` realiza la transformación inversa.

---

## 04.7 — SSM Permissions

Adjuntamos:

```text
AmazonSSMManagedInstanceCore
```

al IAM Role.

El Role por sí solo no concede automáticamente permisos.

---

## 04.8 — Instance Profile

```text
EC2
 ↓
Instance Profile
 ↓
IAM Role
 ↓
Permissions
```

---

## 04.9 — User Data

```bash
#!/bin/bash

set -e

apt-get update -y

echo "Terraform DevSecOps Platform" > /home/ubuntu/terraform-lab.txt
echo "EC2 configured automatically using Terraform User Data" >> /home/ubuntu/terraform-lab.txt

chown ubuntu:ubuntu /home/ubuntu/terraform-lab.txt
```

Terraform lo carga mediante:

```hcl
user_data = file("${path.module}/user-data.sh")
```

Aprendimos:

```text
file()      → lee un archivo
path.module → directorio del módulo actual
```

---

## 04.10 — Troubleshooting de SSM

Inicialmente SSM no funcionaba correctamente.

Investigamos:

```text
IAM Policy        ✅
Instance Profile  ✅
SSM Agent         ✅
Public IP         ✅
Route Table       ✅
Internet Gateway  ✅
Network ACL       ✅
Security Group    ❌
```

Faltaba permitir egress.

Terraform mostró:

```text
~ update in-place

Plan: 0 to add, 1 to change, 0 to destroy.
```

Aprendimos a diagnosticar por capas:

```text
Aplicación / Agent
        ↓
IAM
        ↓
DNS
        ↓
Security Group
        ↓
NACL
        ↓
Route Table
        ↓
Internet Gateway
```

---

## 04.11 — Systems Manager

Verificamos:

```bash
aws ssm describe-instance-information
```

y obtuvimos estado:

```text
Online
```

Necesitamos:

```text
EC2
 ├── SSM Agent
 ├── IAM Role
 ├── Instance Profile
 ├── SSM Permissions
 └── Conectividad
```

---

## 04.12 — Acceso sin SSH

```bash
aws ssm start-session \
  --target <INSTANCE_ID> \
  --profile terraform-lab \
  --region eu-west-1
```

Arquitectura:

```text
Mac
 │
 ▼
AWS Systems Manager
 │
 ▼
SSM Agent
 │
 ▼
EC2
```

No necesitamos:

```text
❌ SSH público
❌ Puerto 22
❌ Key Pair
```

---

## 04.13 — `ssm-user`

Dentro de Session Manager:

```bash
whoami
```

Resultado:

```text
ssm-user
```

También distinguimos:

```text
Permission denied
```

de:

```text
No such file or directory
```

---

## 04.14 — Verificación del User Data

```bash
sudo cat /home/ubuntu/terraform-lab.txt
```

Resultado:

```text
Terraform DevSecOps Platform
EC2 configured automatically using Terraform User Data
```

Flujo:

```text
Terraform
   ↓
EC2
   ↓
User Data
   ↓
cloud-init
   ↓
user-data.sh
```

---

## 04.15 — Verificación del SSM Agent

Comprobamos `amazon-ssm-agent` desde Ubuntu y verificamos que estaba
activo.

Esto confirmó desde AWS y desde la propia instancia que Systems Manager
funcionaba correctamente.

---

# 05 — Terraform intermedio / avanzado

En esta sección profundizamos en mecanismos especialmente importantes
para trabajar con configuraciones reutilizables, realizar
refactorizaciones seguras y preparar **Terraform Associate**.

---

## 05.1 — `count`

```hcl
resource "terraform_data" "count_example" {
  count = length(var.example_servers)

  input = {
    name  = var.example_servers[count.index]
    index = count.index
  }
}
```

Direcciones:

```text
terraform_data.count_example[0]
terraform_data.count_example[1]
terraform_data.count_example[2]
```

Eliminamos `"api"` de la posición intermedia.

Terraform detectó:

```text
[0] web       → sin cambios
[1] api       → worker
[2] worker    → destroy
```

### 🧠 ¿Qué aprendimos?

```text
count → identidad mediante índices numéricos
```

Eliminar o reordenar elementos puede desplazar identidades.

---

## 05.2 — `for_each`

```hcl
resource "terraform_data" "for_each_example" {
  for_each = var.example_services

  input = {
    name = each.value
  }
}
```

Direcciones:

```text
terraform_data.for_each_example["web"]
terraform_data.for_each_example["api"]
terraform_data.for_each_example["worker"]
```

Al eliminar `"api"` únicamente desaparecía:

```text
terraform_data.for_each_example["api"]
```

### 🧠 ¿Qué aprendimos?

```text
count    → índice
for_each → clave estable
```

Con un mapa:

```text
each.key   → clave
each.value → valor
```

---

## 05.3 — Expresiones `for`

Transformación:

```hcl
uppercase_servers = [
  for server in var.example_servers :
  upper(server)
]
```

Filtrado:

```hcl
filtered_servers = [
  for server in var.example_servers :
  upper(server)
  if server != "api"
]
```

Creación de mapa:

```hcl
server_map = {
  for server in var.example_servers :
  server => upper(server)
}
```

### 🧠 ¿Qué aprendimos?

```text
count    → crea instancias
for_each → crea instancias por clave
for      → transforma / filtra colecciones
```

Una expresión `for` no crea recursos por sí sola.

---

## 05.4 — Condicionales

Sintaxis:

```text
condition ? true_value : false_value
```

Ejemplo:

```hcl
example_instance_type = (
  var.example_environment == "prod"
  ? "t3.small"
  : "t3.micro"
)
```

Resultado:

```text
dev  → t3.micro
prod → t3.small
```

También:

```hcl
count = var.create_resource ? 1 : 0
```

permite controlar opcionalmente la creación de recursos.

---

## 05.5 — Funciones

Practicamos:

```text
length()
upper()
lower()
concat()
merge()
lookup()
toset()
tomap()
try()
coalesce()
```

### `concat()`

```hcl
concat(
  ["web", "api"],
  ["worker", "database"]
)
```

Resultado:

```text
["web", "api", "worker", "database"]
```

### `merge()`

```hcl
merge(
  {
    Environment = "dev"
    Project     = "terraform-lab"
  },
  {
    Owner       = "DevSecOps"
    Environment = "prod"
  }
)
```

Resultado:

```text
Environment = "prod"
Project     = "terraform-lab"
Owner       = "DevSecOps"
```

En claves duplicadas:

```text
argumento posterior → tiene prioridad
```

### `lookup()`

```hcl
lookup(
  {
    dev  = "t3.micro"
    prod = "t3.small"
  },
  var.example_environment,
  "t3.micro"
)
```

### `toset()`

Elimina duplicados y produce un set.

### `try()`

```hcl
try(
  local.function_config.description,
  "fallback"
)
```

Puede proporcionar un fallback ante errores adecuados de evaluación
dinámica.

No convierte referencias estáticamente inválidas en referencias válidas.

### `coalesce()`

```hcl
coalesce(
  null,
  "",
  "terraform-lab"
)
```

Resultado:

```text
terraform-lab
```

---

## 05.6 — `dynamic`

Creamos reglas de Security Group mediante:

```hcl
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
```

Generamos:

```text
HTTP        → 80
HTTPS       → 443
Application → 8080
```

### 🧠 ¿Qué aprendimos?

```text
for_each en resource
        ↓
múltiples instancias del recurso

dynamic
        ↓
múltiples bloques anidados
```

`dynamic` **no crea múltiples recursos**.

---

## 05.7 — Dependencias y `depends_on`

Dependencia implícita:

```hcl
vpc_id = aws_vpc.main.id
```

Terraform puede inferir:

```text
VPC
 ↓
Security Group
```

Dependencia explícita:

```hcl
resource "terraform_data" "dependency_application" {
  input = {
    name = "application"
  }

  depends_on = [
    terraform_data.dependency_database
  ]
}
```

### 🧠 ¿Qué aprendimos?

Preferimos dependencias implícitas cuando una referencia puede expresar
la relación.

`depends_on` se utiliza cuando existe una dependencia que Terraform no
puede inferir.

Los nombres de los `.tf` no determinan el orden de creación.

---

## 05.8 — `lifecycle`

Practicamos:

```text
create_before_destroy
prevent_destroy
ignore_changes
replace_triggered_by
```

### `create_before_destroy`

```hcl
lifecycle {
  create_before_destroy = true
}
```

Terraform puede mostrar:

```text
+/- create replacement and then destroy
```

en lugar de:

```text
-/+ destroy and then create replacement
```

### `prevent_destroy`

```hcl
lifecycle {
  prevent_destroy = true
}
```

Terraform bloquea operaciones planificadas que impliquen destruir la
instancia mientras esta regla forme parte de la configuración.

No significa:

```text
❌ protección permanente en AWS
❌ impedir borrados manuales
❌ mantener la protección si eliminamos el resource del código
```

### `ignore_changes`

```hcl
lifecycle {
  ignore_changes = [
    input
  ]
}
```

Terraform puede utilizar el atributo durante la creación pero ignorar
determinados cambios posteriores al planificar actualizaciones.

### `replace_triggered_by`

```hcl
resource "terraform_data" "application" {
  input = "my-application"

  lifecycle {
    replace_triggered_by = [
      terraform_data.application_version
    ]
  }
}
```

Un cambio del recurso referenciado puede provocar el reemplazo.

```text
depends_on
→ dependencia

replace_triggered_by
→ trigger de reemplazo
```

---

## 05.9 — Import

Practicamos con una VPC existente.

Primero:

```bash
terraform state rm aws_vpc.main
```

La VPC continuó existiendo en AWS.

Después:

```bash
terraform import aws_vpc.main vpc-XXXXXXXX
```

Terraform volvió a asociar la VPC con:

```text
aws_vpc.main
```

Finalmente:

```bash
terraform plan -target=aws_vpc.main
```

Resultado:

```text
No changes. Your infrastructure matches the configuration.
```

### 🧠 ¿Qué aprendimos?

```text
terraform import
→ objeto remoto existente → State
```

No crea el objeto remoto.

Después de importar debemos reconciliar configuración, State y realidad
mediante `plan`.

---

## 05.10 — Import Blocks

Forma declarativa:

```hcl
import {
  to = aws_vpc.main
  id = "vpc-XXXXXXXX"
}
```

Un import block puede versionarse, revisarse y participar en el flujo de
`plan/apply`.

El bloque `resource` sigue siendo necesario para describir cómo queremos
gestionar el objeto.

---

## 05.11 — `moved`

Partimos de:

```hcl
resource "terraform_data" "old_name" {
  input = "moved-demo"
}
```

Lo renombramos:

```hcl
resource "terraform_data" "new_name" {
  input = "moved-demo"
}
```

Sin `moved`:

```text
old_name → destroy
new_name → create
```

Declaramos:

```hcl
moved {
  from = terraform_data.old_name
  to   = terraform_data.new_name
}
```

Resultado:

```text
Plan: 0 to add, 0 to change, 0 to destroy.
```

### 🧠 ¿Qué aprendimos?

```text
import
→ incorporar objeto externo al State

moved
→ cambiar dirección de objeto ya gestionado
```

`moved` permite documentar el refactoring en HCL.

---

## 05.12 — Reemplazo con `-replace`

Aunque Terraform muestre:

```text
No changes.
```

podemos solicitar un reemplazo:

```bash
terraform plan -replace=terraform_data.new_name
```

Un flujo controlado:

```bash
terraform plan \
  -replace=terraform_data.new_name \
  -out=tfplan

terraform apply tfplan
```

### 🧠 ¿Qué aprendimos?

```text
-replace
→ solicita explícitamente el reemplazo
```

Ejecutar únicamente `plan -replace` no modifica infraestructura.

---

## 05.13 — `terraform taint`

Workflow histórico:

```bash
terraform taint RESOURCE_ADDRESS
```

Marca una instancia para que Terraform planifique su reemplazo.

Actualmente preferimos normalmente:

```bash
terraform apply -replace=RESOURCE_ADDRESS
```

o:

```bash
terraform plan -replace=RESOURCE_ADDRESS
```

Es importante conocer `taint` para Terraform Associate y proyectos
antiguos.

---

## 05.14 — `-target`

Durante los experimentos utilizamos:

```bash
terraform plan -target=RESOURCE_ADDRESS
terraform apply -target=RESOURCE_ADDRESS
```

para aislar recursos concretos.

### 🧠 ¿Qué aprendimos?

`-target` es una herramienta para situaciones excepcionales,
recuperaciones o experimentos.

**No debe convertirse en el workflow normal de Terraform.**

---

## 05.15 — Limpieza del laboratorio

Antes de destruir revisamos:

```bash
terraform plan -destroy
```

Resultado:

```text
Plan: 0 to add, 0 to change, 27 to destroy.
```

Después:

```bash
terraform destroy
```

Resultado:

```text
Destroy complete! Resources: 27 destroyed.
```

Finalmente:

```bash
terraform state list
```

no devolvió recursos.

El backend S3 continuó existiendo porque pertenece a la configuración
independiente de `bootstrap/`.

---

## 05.16 — Examen Terraform Associate

Finalizamos con un examen de 15 preguntas.

Resultado:

```text
13 / 15
86,7 %
```

Los dos puntos a reforzar fueron:

### `merge()`

```text
En claves duplicadas:
el argumento posterior tiene prioridad.
```

### `for_each` + `dynamic`

```text
for_each en resource
→ crea instancias del recurso

dynamic
→ crea bloques anidados dentro de cada instancia
```

---

## 05.17 — Resumen

```text
count
└── instancias identificadas por índice

for_each
└── instancias identificadas por clave

for
└── transformación / filtrado

dynamic
└── bloques anidados

depends_on
└── dependencia explícita

lifecycle
├── create_before_destroy
├── prevent_destroy
├── ignore_changes
└── replace_triggered_by

import
└── objeto existente → State

state rm
└── eliminar asociación sin destruir objeto

moved
└── dirección antigua → dirección nueva

-replace
└── solicitar reemplazo

taint
└── workflow histórico de reemplazo
```


---

# 🔐 Arquitectura desarrollada

Durante las secciones 03 y 04 desplegamos la siguiente arquitectura:

```text
                       TERRAFORM CLI
                            │
            ┌───────────────┴────────────────┐
            │                                │
            ▼                                ▼
       Backend S3                       AWS Provider
            │                                │
            ▼                                ▼
 dev/terraform.tfstate                     AWS
            │                                │
     ┌──────┼──────┐                         │
     │      │      │                         │
 Version  Encrypt  Lock                      │
     │      │      │                         │
     └──────┴──────┘                         │
                                             ▼
                                    VPC 10.0.0.0/16
                                             │
                         ┌───────────────────┴──────────────────┐
                         │                                      │
                  Public Subnet                          Private Subnet
                   10.0.1.0/24                            10.0.2.0/24
                         │
                         ▼
                        EC2
                   Ubuntu 24.04
                     t2.micro
                         │
                ┌────────┴─────────┐
                │                  │
         Security Group       Instance Profile
                │                  │
        Ingress: none          IAM Role
        Egress: allowed            │
                                   ▼
                        AmazonSSMManagedInstanceCore
                                   │
                                   ▼
                           Systems Manager
                                   │
                                   ▼
                            Session Manager
                                   │
                                   ▼
                         Administración segura
                              sin SSH / 22
```

> La infraestructura de laboratorio fue destruida de forma controlada al
> finalizar la sección 05. El código Terraform permanece versionado para
> poder reproducirla posteriormente.

El Remote State continúa almacenado en el backend S3 independiente.

---

# 🔐 Git y seguridad

`.gitignore` protege archivos locales:

```gitignore
# Terraform working directory
.terraform/

# Terraform state
*.tfstate
*.tfstate.*

# Terraform variable files
*.tfvars
*.tfvars.json

# Terraform plan files
*.tfplan
tfplan

# Terraform crash logs
crash.log
crash.*.log

# Terraform override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Local Terraform CLI configuration
.terraformrc
terraform.rc

# macOS
.DS_Store
```

Sí versionamos normalmente:

```text
*.tf
README.md
.gitignore
.terraform.lock.hcl
user-data.sh
```

No versionamos:

```text
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
tfplan
.terraform/
```

### 🧠 ¿Qué aprendimos?

El State puede contener información sensible.

`.terraform.lock.hcl`:

```text
NO es Terraform State
NO es State Lock
SÍ registra selecciones de providers
```

Normalmente debe versionarse.

---

# 🔄 Flujo de trabajo

```text
          ┌───────────────────────┐
          │  Entender el cambio   │
          └───────────┬───────────┘
                      ▼
          ┌───────────────────────┐
          │  Escribir Terraform   │
          └───────────┬───────────┘
                      ▼
             terraform fmt
                      ▼
           terraform validate
                      ▼
             terraform plan
                      ▼
              REVISAR PLAN
                      ▼
             terraform apply
                      ▼
            Verificar en AWS
                      ▼
             Verificar CLI
                      ▼
          Diagnosticar errores
                      ▼
             Documentación
                      ▼
               Git commit
```

Para destrucciones:

```text
terraform plan -destroy
          ↓
      REVISAR
          ↓
terraform destroy
          ↓
terraform state list
          ↓
      VERIFICAR
```

---

# ⚠️ Regla fundamental

Nunca aplicar cambios sin entender primero el plan.

```text
+     create
~     update in-place
-     destroy
-/+   destroy → create
+/-   create → destroy
```

Si aparece una destrucción inesperada:

```text
STOP
 ↓
Investigar
 ↓
Entender
 ↓
Corregir
 ↓
Volver a planificar
 ↓
Aplicar únicamente cuando sea correcto
```

---

# 🧪 Comandos Terraform utilizados

## Inicialización

```bash
terraform init
terraform init -migrate-state
```

## Formato y validación

```bash
terraform fmt
terraform validate
```

## Planificación

```bash
terraform plan
terraform plan -out=tfplan
terraform plan -destroy
terraform plan -replace=RESOURCE_ADDRESS
```

## Aplicación

```bash
terraform apply
terraform apply tfplan
```

## Destrucción

```bash
terraform destroy
```

## Outputs

```bash
terraform output
terraform output ec2_instance_id
terraform output -raw ec2_instance_id
```

## Inspección

```bash
terraform show
```

## State

```bash
terraform state list
terraform state show RESOURCE_ADDRESS
terraform state mv ORIGEN DESTINO
terraform state rm RESOURCE_ADDRESS
```

## Import

```bash
terraform import RESOURCE_ADDRESS REMOTE_ID
```

## Operaciones especiales estudiadas

```bash
terraform plan -target=RESOURCE_ADDRESS
terraform apply -target=RESOURCE_ADDRESS

terraform plan -replace=RESOURCE_ADDRESS
terraform apply -replace=RESOURCE_ADDRESS

terraform taint RESOURCE_ADDRESS
terraform force-unlock LOCK_ID
```

`-target` se utilizó para experimentos controlados y no como workflow
habitual.

---

# 🧪 AWS CLI utilizada

Utilizamos AWS CLI para verificar:

```text
VPC
Subnets
Route Tables
Internet Gateway
Security Groups
Network ACL
EC2
IAM
Systems Manager
S3
S3 Versioning
```

Systems Manager:

```bash
aws ssm describe-instance-information
```

```bash
aws ssm start-session \
  --target <INSTANCE_ID> \
  --profile terraform-lab \
  --region eu-west-1
```

Remote State:

```bash
aws s3 ls s3://terraform-aws-devsecops-dt97-state/ --recursive \
  --profile terraform-lab
```

Versioning:

```bash
aws s3api list-object-versions \
  --bucket terraform-aws-devsecops-dt97-state \
  --prefix dev/terraform.tfstate \
  --profile terraform-lab
```

---

# 🧠 Conceptos aprendidos

## Terraform Core

- Infrastructure as Code.
- Configuración declarativa.
- Providers.
- Backends.
- Resources.
- Data Sources.
- Terraform State.
- Local State.
- Remote State.
- S3 Backend.
- State Migration.
- State Locking.
- State Versioning.
- State Encryption.
- Dependency Graph.
- Dependencias implícitas.
- Dependencias explícitas.
- Variables.
- `terraform.tfvars`.
- Locals.
- Outputs.
- `(known after apply)`.
- Saved Plans.
- Update in-place.
- Resource replacement.
- Drift.
- Idempotencia.
- Provider/API validation.
- `.terraform.lock.hcl`.

## Meta-arguments y expresiones

- `count`.
- `count.index`.
- `for_each`.
- `each.key`.
- `each.value`.
- Expresiones `for`.
- Filtrado de colecciones.
- Expresiones condicionales.
- `depends_on`.
- `lifecycle`.
- `create_before_destroy`.
- `prevent_destroy`.
- `ignore_changes`.
- `replace_triggered_by`.

## Funciones

- `length()`.
- `upper()`.
- `lower()`.
- `concat()`.
- `merge()`.
- `lookup()`.
- `toset()`.
- `tomap()`.
- `try()`.
- `coalesce()`.
- `file()`.
- `jsonencode()`.
- `jsondecode()`.

## Bloques y refactoring

- Dynamic Blocks.
- Import.
- Import Blocks.
- Moved Blocks.
- `terraform state mv`.
- `terraform state rm`.
- Refactoring seguro.
- `-replace`.
- `terraform taint`.
- `-target`.
- Destrucción controlada.

## AWS Networking

- VPC.
- CIDR.
- Public / Private Subnets.
- Availability Zones.
- Internet Gateway.
- Route Tables.
- Routes.
- Default Route.
- Local Route.
- Associations.
- Main Route Table.
- Security Groups.
- Network ACL.
- Stateful vs Stateless.
- Public IPv4.

## AWS Compute

- EC2.
- AMI.
- Ubuntu Server.
- Instance Type.
- User Data.
- cloud-init.
- Public / Private IP.

## AWS IAM

- IAM Role.
- Trust Policy.
- Permissions Policy.
- `sts:AssumeRole`.
- Managed Policies.
- Policy Attachment.
- Instance Profile.

## AWS Systems Manager

- SSM Agent.
- Session Manager.
- Managed Instance.
- `ssm-user`.
- Administración sin SSH.
- Diagnóstico de conectividad.

## Amazon S3

- Bucket.
- Public Access Block.
- Server-Side Encryption.
- AES256 / SSE-S3.
- Versioning.
- Remote Terraform State.
- Native S3 State Locking.
- `.tflock`.

## DevOps / DevSecOps

- Git.
- GitHub.
- `.gitignore`.
- Infrastructure versioning.
- Incremental changes.
- Validation before deployment.
- AWS CLI verification.
- Troubleshooting por capas.
- Documentación.
- Reducción de superficie de exposición.
- Automatización de configuración.

---

# 📊 Estado actual

```text
Terraform AWS DevSecOps Platform
│
├── 00 — Plan general                            ✅
│
├── 01 — Fundamentos Terraform                   ✅
│   ├── Provider / Resources / Data              ✅
│   ├── Variables / tfvars / locals              ✅
│   ├── Outputs                                  ✅
│   ├── Dependency Graph                         ✅
│   ├── fmt / validate / plan / apply            ✅
│   └── Plan guardado                            ✅
│
├── 02 — State y Backend remoto                  ✅
│   ├── State local                              ✅
│   ├── State commands                           ✅
│   ├── Bootstrap                                ✅
│   ├── S3 Backend                               ✅
│   ├── Public Access Block                      ✅
│   ├── Encryption                               ✅
│   ├── Versioning                               ✅
│   ├── State Locking                            ✅
│   ├── Migración local → S3                     ✅
│   └── Import / recuperación                    ✅
│
├── 03 — AWS Networking                          ✅
│   ├── VPC                                      ✅
│   ├── Public Subnet                            ✅
│   ├── Private Subnet                           ✅
│   ├── Internet Gateway                         ✅
│   ├── Route Tables                             ✅
│   ├── Routes / Associations                    ✅
│   └── Security Group                           ✅
│
├── 04 — Compute / EC2                           ✅
│   ├── Ubuntu AMI Data Source                   ✅
│   ├── EC2 t2.micro                             ✅
│   ├── IAM Role                                 ✅
│   ├── SSM Policy                               ✅
│   ├── Instance Profile                         ✅
│   ├── User Data                                ✅
│   ├── SSM Agent                                ✅
│   ├── Session Manager                          ✅
│   ├── Acceso sin SSH                           ✅
│   └── Troubleshooting SSM                      ✅
│
├── 05 — Terraform intermedio / avanzado         ✅
│   ├── count                                    ✅
│   ├── for_each                                 ✅
│   ├── for expressions                          ✅
│   ├── Conditional expressions                  ✅
│   ├── Functions                                ✅
│   ├── Dynamic blocks                           ✅
│   ├── depends_on                               ✅
│   ├── lifecycle                                ✅
│   │   ├── create_before_destroy                ✅
│   │   ├── prevent_destroy                      ✅
│   │   ├── ignore_changes                       ✅
│   │   └── replace_triggered_by                 ✅
│   ├── import / import blocks                   ✅
│   ├── state rm                                 ✅
│   ├── moved blocks                             ✅
│   ├── -replace / taint                         ✅
│   ├── Limpieza del laboratorio                 ✅
│   └── Examen Terraform Associate: 13/15        ✅
│
└── 06 — Módulos y estructura profesional        ⏳
```

---

# 🎓 Puntos importantes para Terraform Associate

## Configuration, State e infraestructura

```text
Configuration ≠ State ≠ Infrastructure
```

```text
Configuration
¿Qué quiero?
      │
      ▼
State
¿Qué gestiona Terraform?
      │
      ▼
Provider
¿Cómo interactúa?
      │
      ▼
AWS
¿Qué existe realmente?
```

El backend responde:

```text
¿Dónde y cómo almacenamos el State?
```

---

## Provider vs Backend

```text
Provider ≠ Backend
```

```text
Provider → comunicación con AWS
Backend  → almacenamiento del State
```

---

## Resource vs Data Source

```text
resource ≠ data
```

```text
resource → gestionar infraestructura
data     → consultar información
```

---

## Lock file vs State Lock

```text
.terraform.lock.hcl ≠ State Lock
```

```text
.terraform.lock.hcl
→ providers

State Lock
→ concurrencia
```

---

## Versioning vs Locking

```text
S3 Versioning ≠ State Locking
```

```text
Versioning → recuperación / historial
Locking    → concurrencia
```

---

## Sensitive

```text
sensitive = true ≠ State cifrado
```

---

## State RM

```text
terraform state rm ≠ terraform destroy
```

```text
state rm
→ deja de gestionar

destroy
→ elimina infraestructura
```

---

## Import

```text
terraform import ≠ crear infraestructura
```

```text
import
→ objeto existente → State
```

---

## `count` vs `for_each`

```text
count
→ identidad mediante índices

for_each
→ identidad mediante claves
```

Cambiar una lista utilizada por `count` puede desplazar índices.

Las claves de `for_each` permiten representar identidades más estables.

---

## `for` expressions

```text
for expression ≠ creación de recursos
```

Una expresión `for` transforma o filtra colecciones.

---

## `dynamic`

```text
dynamic
→ genera bloques anidados
```

No crea recursos independientes.

---

## Dependencias

```text
referencia directa
→ dependencia implícita

depends_on
→ dependencia explícita
```

Siempre que una referencia represente correctamente la relación,
preferimos la dependencia implícita.

---

## `depends_on` vs `replace_triggered_by`

```text
depends_on
→ dependencia

replace_triggered_by
→ reemplazo provocado por cambios
```

---

## `prevent_destroy`

```text
prevent_destroy ≠ protección permanente en AWS
```

Funciona mientras la regla esté presente en la configuración.

---

## `ignore_changes`

```text
ignore_changes
→ Terraform deja de reconciliar determinados cambios
```

Debe utilizarse conscientemente.

---

## `import` vs `moved`

```text
import
→ objeto externo entra bajo gestión

moved
→ objeto gestionado cambia de dirección
```

---

## `state mv` vs `moved`

```text
terraform state mv
→ operación CLI sobre State

moved block
→ refactoring declarativo y versionable
```

---

## `-replace` vs `taint`

```text
-replace
→ enfoque actual para solicitar reemplazo

taint
→ workflow histórico
```

---

## `merge()`

```text
merge()
→ en claves duplicadas prevalece el argumento posterior
```

Ejemplo:

```hcl
merge(
  { Environment = "dev" },
  { Environment = "prod" }
)
```

Resultado:

```text
Environment = "prod"
```

---

## `-target`

```text
-target
→ herramienta excepcional
→ NO workflow habitual
```

---

## Validate, Plan y Apply

```text
validate correcto ≠ plan garantizado
plan correcto     ≠ apply garantizado
```

Cada fase comprueba cosas diferentes.

---

## `(known after apply)`

```text
(known after apply) ≠ error
```

Terraform simplemente no conoce todavía el valor definitivo.

---

# 🚀 Próximos pasos

Los bloques **00–05 están completados**.

El siguiente bloque será:

# 06 — Módulos y estructura profesional

Hasta ahora nuestra configuración principal funciona como un único
**Root Module**:

```text
ROOT MODULE
│
├── backend.tf
├── providers.tf
├── variables.tf
├── locals.tf
├── network.tf
├── security.tf
├── compute.tf
├── iam.tf
├── advanced.tf
└── outputs.tf
```

El siguiente objetivo será comprender cómo dividir responsabilidades en
módulos reutilizables.

Conceptualmente evolucionaremos hacia:

```text
ROOT MODULE
│
├── module.network
│   ├── VPC
│   ├── Subnets
│   ├── Internet Gateway
│   └── Route Tables
│
├── module.security
│   └── Security Groups
│
└── module.compute
    ├── EC2
    ├── IAM
    └── SSM
```

Estudiaremos:

- Qué es un módulo Terraform.
- Root Module.
- Child Modules.
- Inputs.
- Outputs.
- Sources locales.
- Sources remotos.
- Terraform Registry.
- Versionado de módulos.
- Reutilización.
- Composición de módulos.
- Buenas prácticas.
- Refactoring de infraestructura existente.
- Implicaciones de los cambios de dirección en el State.

Posteriormente evolucionaremos hacia:

```text
Terraform
    │
    ▼
Módulos
    │
    ▼
Entornos
    │
    ▼
Security / DevSecOps
    │
    ▼
CI/CD
    │
    ├── terraform fmt
    ├── terraform validate
    ├── Security Scanning
    ├── terraform plan
    ├── Approval
    └── terraform apply
             │
             ▼
            AWS

Remote State ─────────────► Amazon S3
```

El objetivo final es combinar:

**Terraform + AWS + Infrastructure as Code + Módulos + Automatización +
CI/CD + DevSecOps**

manteniendo siempre una regla:

> **No añadir tecnología por añadirla. Cada componente debe resolver una
> necesidad concreta y debemos entender por qué existe.**