# Plataforma DevSecOps en AWS con Terraform

Proyecto práctico para aprender **Terraform sobre AWS** construyendo una infraestructura real de forma progresiva y entendiendo qué hace cada recurso antes de avanzar al siguiente.

El objetivo no es únicamente desplegar infraestructura, sino aprender un flujo de trabajo profesional con **Infrastructure as Code (IaC)**:

**entender → implementar → formatear → validar → planificar → aplicar → verificar → documentar → versionar**

> 🚧 Estado actual: **Networking + Compute / EC2 completados**.  
> 🔐 La instancia EC2 puede administrarse mediante **AWS Systems Manager Session Manager sin SSH ni puerto 22 abierto**.

---

# 🎯 Objetivos del proyecto

Este proyecto tiene como objetivos:

- Aprender Terraform de forma práctica.
- Preparar conceptos importantes para **Terraform Associate**.
- Construir infraestructura AWS desde cero.
- Entender las dependencias entre recursos.
- Aprender arquitectura básica de redes en AWS.
- Aplicar buenas prácticas de organización.
- Evitar valores hardcodeados.
- Utilizar variables, locals, data sources y outputs.
- Comprender el Terraform State.
- Validar cada cambio antes de modificar AWS.
- Verificar la infraestructura mediante AWS CLI.
- Diagnosticar problemas reales de infraestructura.
- Versionar Infrastructure as Code mediante Git.
- Aplicar progresivamente buenas prácticas de seguridad.
- Evitar SSH cuando existe una alternativa más segura.
- Automatizar configuración mediante User Data.
- Evolucionar hacia una plataforma orientada a **DevOps / DevSecOps y CI/CD**.

---

# 🧰 Tecnologías

| Tecnología | Uso |
|---|---|
| Terraform | Infrastructure as Code |
| AWS | Cloud Provider |
| AWS EC2 | Compute |
| AWS IAM | Roles y permisos |
| AWS Systems Manager | Administración remota segura |
| AWS CLI | Verificación y diagnóstico |
| Ubuntu Server 24.04 LTS | Sistema operativo EC2 |
| Git | Control de versiones |
| GitHub | Repositorio remoto |

Región AWS:

```text
eu-west-1
```

Availability Zone:

```text
eu-west-1a
```

---

# 📁 Estructura actual

```text
terraform-aws-devsecops-platform/
│
├── versions.tf
├── providers.tf
│
├── variables.tf
├── terraform.tfvars
├── locals.tf
│
├── network.tf
├── security.tf
├── compute.tf
├── iam.tf
│
├── user-data.sh
│
├── outputs.tf
│
├── README.md
└── .gitignore
```

Terraform interpreta todos los archivos `.tf` del mismo directorio como una única configuración.

Por tanto, no es obligatorio utilizar un único `main.tf`.

Podemos separar los recursos por responsabilidad:

```text
network.tf   → Networking
security.tf  → Security Groups
compute.tf   → EC2 / Compute
iam.tf       → IAM
outputs.tf   → Outputs
```

El nombre y orden de los archivos **no determina el orden de creación de los recursos**.

Terraform utiliza su **Dependency Graph** para determinar las dependencias.

---

# 01 — Configuración inicial de Terraform

Antes de crear infraestructura se preparó el proyecto Terraform.

La configuración se separó en distintos archivos para evitar concentrar todo el código en un único fichero.

## Archivos principales

### `versions.tf`

Contiene los requisitos relacionados con Terraform y los providers utilizados.

### `providers.tf`

Configura el provider AWS.

### `variables.tf`

Declara las variables de entrada.

### `terraform.tfvars`

Proporciona valores para nuestras variables.

### `locals.tf`

Contiene valores internos reutilizables.

### `network.tf`

Contiene los recursos de networking.

### `security.tf`

Contiene los Security Groups.

### `compute.tf`

Contiene la instancia EC2 y la búsqueda de la AMI.

### `iam.tf`

Contiene IAM Role, Policy Attachment e Instance Profile.

### `outputs.tf`

Expone información útil de la infraestructura.

### `user-data.sh`

Contiene el script ejecutado automáticamente durante el primer arranque de la instancia.

## 🧠 ¿Qué aprendimos?

Terraform carga conjuntamente todos los archivos `.tf` existentes en el mismo directorio.

```text
network.tf
security.tf
compute.tf
iam.tf
outputs.tf
        │
        ▼
UNA configuración Terraform
```

El orden de los archivos no determina el orden de creación.

Terraform determina el orden mediante las relaciones entre recursos.

---

# 02 — Networking

La primera infraestructura construida fue la capa de red.

## 🏗️ Arquitectura de red

```text
                              INTERNET
                                  │
                                  │
                         Internet Gateway
                                  │
                                  │
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

## 02.1 — VPC

CIDR:

```text
10.0.0.0/16
```

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

### 🧠 ¿Qué aprendimos?

La VPC representa nuestra red privada dentro de AWS.

En lugar de hardcodear IDs:

```text
vpc-xxxxxxxx
```

utilizamos referencias:

```hcl
aws_vpc.main.id
```

Esto permite a Terraform construir dependencias implícitas.

---

## 02.2 — Public Subnet

CIDR:

```text
10.0.1.0/24
```

```hcl
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id

  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name    = "${local.name_prefix}-public-subnet"
    Project = var.project_name
  }
}
```

### 🧠 ¿Qué aprendimos?

Una subnet no es pública por llamarse `public`.

Necesita routing adecuado hacia un Internet Gateway.

Un `/24` contiene 256 direcciones IPv4 y AWS reserva cinco direcciones por subnet, por lo que quedan 251 utilizables.

---

## 02.3 — Private Subnet

CIDR:

```text
10.0.2.0/24
```

```hcl
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id

  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name    = "${local.name_prefix}-private-subnet"
    Project = var.project_name
  }
}
```

### 🧠 ¿Qué aprendimos?

La diferencia fundamental entre nuestras subnets está en el routing.

Actualmente la subnet privada no dispone de:

```text
0.0.0.0/0 → IGW
```

---

## 02.4 — Internet Gateway

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${local.name_prefix}-igw"
    Project = var.project_name
  }
}
```

### 🧠 ¿Qué aprendimos?

Crear un Internet Gateway no convierte automáticamente una subnet en pública.

Necesitamos:

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

## 02.5 — Public Route Table

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${local.name_prefix}-public-rt"
    Project = var.project_name
  }
}
```

AWS añade automáticamente:

```text
10.0.0.0/16 → local
```

### 🧠 ¿Qué aprendimos?

La ruta `local` permite routing interno dentro de la VPC.

El routing no significa automáticamente que el tráfico esté permitido. También intervienen Security Groups y Network ACLs.

---

## 02.6 — Public Internet Route

```hcl
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
```

Resultado:

```text
10.0.0.0/16 → local
0.0.0.0/0   → IGW
```

### 🧠 ¿Qué aprendimos?

`0.0.0.0/0` representa cualquier destino IPv4 que no coincida con una ruta más específica.

---

## 02.7 — Public Route Table Association

```hcl
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

### 🧠 ¿Qué aprendimos?

Crear una Route Table no es suficiente.

Debemos asociarla con la subnet que debe utilizarla.

---

## 02.8 — Private Route Table

```hcl
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${local.name_prefix}-private-rt"
    Project = var.project_name
  }
}
```

Actualmente:

```text
10.0.0.0/16 → local
```

### 🧠 ¿Qué aprendimos?

Podemos utilizar diferentes Route Tables para aplicar comportamientos diferentes a cada subnet.

---

## 02.9 — Private Route Table Association

```hcl
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

Resultado:

```text
VPC
│
├── Public Subnet
│       ↓
│   Public RT
│       └── 0.0.0.0/0 → IGW
│
└── Private Subnet
        ↓
    Private RT
        └── local only
```

---

## 02.10 — Main Route Table

Durante las verificaciones encontramos una tercera Route Table que no habíamos definido explícitamente.

AWS crea automáticamente una **Main Route Table** al crear una VPC.

### 🧠 ¿Qué aprendimos?

No todos los recursos que aparecen en AWS tienen que haber sido creados explícitamente mediante un bloque `resource`.

AWS puede crear recursos asociados automáticamente.

---

## 02.11 — Security Group

Creamos un Security Group para nuestra instancia.

Actualmente no permitimos tráfico entrante.

Sí permitimos tráfico saliente:

```hcl
resource "aws_security_group" "terraform_lab" {
  name        = "${local.name_prefix}-sg"
  description = "security group for terraform learning project"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "allow all outbound traffic"

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${local.name_prefix}-sg"
    Project = var.project_name
  }
}
```

### 🧠 ¿Qué aprendimos?

Un Security Group pertenece a una VPC y posteriormente puede asociarse a recursos como EC2.

`protocol = "-1"` representa todos los protocolos.

El Security Group mantiene:

```text
Ingress → ninguno
Egress  → permitido
```

Esto nos permite administrar EC2 mediante SSM sin abrir SSH.

También diferenciamos:

```text
Security Group → stateful
Network ACL    → stateless
```

---

# 03 — Variables y reutilización

Las variables permiten parametrizar nuestra infraestructura.

Actualmente utilizamos:

```text
project_name
vpc_cidr
public_subnet_cidr
private_subnet_cidr
availability_zone
instance_type
```

Ejemplo:

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
```

## 🧠 ¿Qué aprendimos?

Una variable puede obtener su valor desde diferentes fuentes.

Entre ellas:

```text
default
terraform.tfvars
*.auto.tfvars
-var
-var-file
TF_VAR_...
```

Este punto es especialmente importante para **Terraform Associate**.

---

## 03.1 — terraform.tfvars

Actualmente contiene valores similares a:

```hcl
project_name = "terraform-aws-devsecops-platform"

vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

availability_zone = "eu-west-1a"

instance_type = "t2.micro"
```

Conceptualmente:

```text
variables.tf
    ↓
¿Qué necesito?

terraform.tfvars
    ↓
¿Qué valor utilizo?
```

---

## 03.2 — Locals

```hcl
locals {
  name_prefix = "terraform-lab"
}
```

### 🧠 ¿Qué aprendimos?

```text
var.xxx
   ↓
Entrada configurable
```

frente a:

```text
local.xxx
   ↓
Valor interno reutilizable
```

---

# 04 — Outputs

Utilizamos outputs para obtener información útil después del despliegue.

Entre otros:

```text
vpc_id
public_subnet_id
private_subnet_id
internet_gateway_id
public_route_table_id
private_route_table_id
security_group_id
ubuntu_ami_id
ec2_instance_id
ec2_public_ip
ec2_private_ip
ec2_iam_role_name
```

Ejemplo:

```hcl
output "ec2_instance_id" {
  description = "ID of the DevSecOps EC2 instance"
  value       = aws_instance.devsecops.id
}
```

## 🧠 ¿Qué aprendimos?

Los outputs permiten exponer valores de nuestra infraestructura.

Podemos consultarlos mediante:

```bash
terraform output
```

o:

```bash
terraform output ec2_instance_id
```

y obtener solamente el valor:

```bash
terraform output -raw ec2_instance_id
```

---

# 05 — Compute / EC2

Una vez completado Networking desplegamos nuestra primera carga de trabajo.

La arquitectura evolucionó hasta:

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
         IAM Instance Profile
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

## 05.1 — AMI mediante Data Source

No hardcodeamos directamente una AMI.

Utilizamos:

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

### 🧠 ¿Qué aprendimos?

Diferenciamos:

```text
resource
   ↓
Crear y administrar infraestructura
```

de:

```text
data
   ↓
Consultar información existente
```

Terraform no crea la AMI.

Consulta AWS para encontrar una AMI que cumpla nuestros filtros.

Además:

```hcl
most_recent = true
```

significa que el resultado puede cambiar cuando Canonical publique una AMI más reciente.

Por tanto, un Data Source **no tiene por qué devolver siempre el mismo valor**.

---

## 05.2 — `terraform validate` vs `terraform plan`

Durante la configuración de la AMI introdujimos accidentalmente un filtro incorrecto.

Terraform aceptó:

```bash
terraform validate
```

pero:

```bash
terraform plan
```

falló cuando AWS recibió el filtro.

### 🧠 ¿Qué aprendimos?

`terraform validate` comprueba que la configuración Terraform sea válida a nivel de sintaxis y estructura que Terraform/provider puede validar localmente.

No garantiza que todos los valores sean aceptados posteriormente por la API remota.

Por eso:

```text
validate correcto
```

no garantiza:

```text
plan correcto
```

ni:

```text
apply correcto
```

---

## 05.3 — EC2

Creamos nuestra instancia:

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

### 🧠 ¿Qué aprendimos?

La instancia utiliza referencias a otros recursos:

```text
data.aws_ami.ubuntu.id
var.instance_type
aws_subnet.public.id
aws_security_group.terraform_lab.id
aws_iam_instance_profile.ec2_ssm.name
```

Estas referencias permiten a Terraform construir su Dependency Graph.

Por ejemplo:

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

No necesitamos indicar manualmente el orden de creación.

---

## 05.4 — `(known after apply)`

Durante `terraform plan` aparecieron valores como:

```text
(known after apply)
```

### 🧠 ¿Qué aprendimos?

Esto significa que Terraform conoce el atributo pero no puede determinar todavía su valor definitivo.

Por ejemplo:

```text
EC2 ID
Public IP
Private IP
```

pueden ser asignados por AWS durante la creación.

Por tanto:

```text
(known after apply)
```

no significa error.

Significa que Terraform conocerá el valor después de crear o modificar el recurso.

---

## 05.5 — IAM Role para EC2

Creamos un IAM Role:

```hcl
resource "aws_iam_role" "ec2_ssm" {
  name = "${local.name_prefix}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${local.name_prefix}-ec2-ssm-role"
    Project = var.project_name
  }
}
```

### 🧠 ¿Qué aprendimos?

Diferenciamos dos conceptos:

```text
Trust Policy
     ↓
¿QUIÉN puede asumir el Role?
```

y:

```text
Permissions Policy
     ↓
¿QUÉ puede hacer el Role?
```

Nuestra Trust Policy permite:

```text
EC2
 ↓
sts:AssumeRole
 ↓
IAM Role
```

---

## 05.6 — `jsonencode()`

La Trust Policy se define utilizando:

```hcl
jsonencode(...)
```

### 🧠 ¿Qué aprendimos?

`jsonencode()` transforma:

```text
Terraform / HCL value
        ↓
JSON string
```

Mientras que:

```hcl
jsondecode()
```

realiza conceptualmente lo contrario:

```text
JSON
 ↓
Terraform value
```

---

## 05.7 — AmazonSSMManagedInstanceCore

Adjuntamos la política administrada de AWS:

```hcl
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

### 🧠 ¿Qué aprendimos?

El IAM Role por sí solo no proporciona automáticamente los permisos necesarios para SSM.

Necesitamos asociar permisos.

```text
EC2
 ↓
IAM Role
 ↓
AmazonSSMManagedInstanceCore
 ↓
Permisos necesarios para Systems Manager
```

---

## 05.8 — IAM Instance Profile

Creamos:

```hcl
resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${local.name_prefix}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name

  tags = {
    Name    = "${local.name_prefix}-ec2-ssm-profile"
    Project = var.project_name
  }
}
```

Y lo asociamos a EC2:

```hcl
iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name
```

### 🧠 ¿Qué aprendimos?

Para asociar el Role con EC2 utilizamos un **Instance Profile**.

```text
EC2
 ↓
Instance Profile
 ↓
IAM Role
 ↓
Permissions
```

Terraform detecta una dependencia implícita gracias a la referencia al Instance Profile.

---

## 05.9 — User Data

Creamos:

```text
user-data.sh
```

con:

```bash
#!/bin/bash

set -e

apt-get update -y

echo "Terraform DevSecOps Platform" > /home/ubuntu/terraform-lab.txt
echo "EC2 configured automatically using Terraform User Data" >> /home/ubuntu/terraform-lab.txt

chown ubuntu:ubuntu /home/ubuntu/terraform-lab.txt
```

Y Terraform carga el archivo mediante:

```hcl
user_data = file("${path.module}/user-data.sh")
```

### 🧠 ¿Qué aprendimos?

La función:

```hcl
file()
```

lee el contenido de un archivo.

Mientras:

```hcl
path.module
```

representa el directorio del módulo actual.

Esto evita depender de una ruta absoluta de nuestro ordenador.

También aprendimos que User Data permite automatizar la configuración inicial de una instancia.

---

## 05.10 — Primera creación de Compute

Terraform mostró:

```text
Plan: 4 to add, 0 to change, 0 to destroy.
```

Después:

```text
Apply complete!
Resources: 4 added, 0 changed, 0 destroyed.
```

### 🧠 ¿Qué aprendimos?

Antes de aplicar revisamos siempre:

```text
to add
to change
to destroy
```

Los símbolos principales de Terraform Plan son:

```text
+     create
~     update in-place
-     destroy
-/+   destroy and create replacement
```

Un:

```text
~ update in-place
```

significa que Terraform puede modificar el recurso existente sin sustituirlo.

Mientras:

```text
-/+
```

indica que el recurso necesita ser reemplazado.

---

## 05.11 — Verificación de EC2

AWS CLI confirmó:

```text
Instance Type → t2.micro
State         → running
Subnet        → Public Subnet
VPC           → nuestra VPC
Public IPv4   → asignada
Private IPv4  → asignada
IAM Profile   → terraform-lab-ec2-ssm-profile
```

### 🧠 ¿Qué aprendimos?

Una subnet pública por sí sola no garantiza que una EC2 tenga conectividad pública.

Debemos considerar conjuntamente:

```text
EC2
 │
 ├── Public IP
 ├── Public Subnet
 ├── Route Table
 ├── Internet Gateway
 ├── Security Group
 └── Network ACL
```

---

## 05.12 — Primer problema real: SSM Offline

Después del despliegue comprobamos:

```bash
aws ssm describe-instance-information
```

pero la instancia no aparecía correctamente registrada.

Investigamos paso a paso:

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

El Security Group tenía:

```text
Ingress: []
Egress:  []
```

### 🧠 ¿Qué aprendimos?

No necesitábamos abrir tráfico entrante para SSM.

El problema era el tráfico **saliente**.

SSM Agent necesita iniciar conexiones hacia los servicios de AWS.

Sin egress:

```text
EC2
 │
 X
 │
 ▼
SSM Endpoint
```

el agente no podía comunicarse con Systems Manager.

---

## 05.13 — Diagnóstico mediante logs

Los logs mostraron errores del SSM Agent al intentar comunicarse con:

```text
https://ssm.eu-west-1.amazonaws.com/
```

y la conexión terminaba en timeout.

También observamos problemas durante:

```bash
apt-get update
```

### 🧠 ¿Qué aprendimos?

Los errores permitieron distinguir entre diferentes posibles causas.

- DNS funcionaba porque el endpoint podía resolverse.
- SSM Agent estaba instalado y ejecutándose.
- IAM estaba correctamente asociado.
- El problema se encontraba en la conectividad de red.

Esto demuestra la importancia de diagnosticar por capas:

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

## 05.14 — Corrección del Security Group

Añadimos:

```hcl
egress {
  description = "allow all outbound traffic"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

Terraform mostró:

```text
~ update in-place
```

y:

```text
Plan: 0 to add, 1 to change, 0 to destroy.
```

### 🧠 ¿Qué aprendimos?

Terraform pudo modificar el Security Group sin destruirlo.

Esto es un:

```text
update in-place
```

y no un:

```text
replacement
```

---

## 05.15 — Security Group vs Network ACL

Durante el diagnóstico también comprobamos la Network ACL.

La NACL permitía el tráfico necesario.

### 🧠 ¿Qué aprendimos?

Una diferencia importante:

```text
Security Group
   ↓
Stateful
```

frente a:

```text
Network ACL
   ↓
Stateless
```

Los Security Groups mantienen el estado de las conexiones.

Las Network ACL evalúan tráfico de entrada y salida de forma independiente.

---

## 05.16 — AWS Systems Manager Online

Después de corregir la conectividad y reiniciar la instancia, verificamos:

```bash
aws ssm describe-instance-information
```

Resultado:

```text
PingStatus   → Online
Platform     → Ubuntu
Version      → 24.04
AgentVersion → 3.3.4793.0
```

### 🧠 ¿Qué aprendimos?

Para que Session Manager funcione necesitamos varias piezas:

```text
EC2
 │
 ├── SSM Agent
 ├── IAM Role
 ├── Instance Profile
 ├── SSM Permissions
 └── Conectividad hacia SSM
```

Si cualquiera de ellas falla, la instancia puede no aparecer como `Online`.

---

## 05.17 — Acceso sin SSH

Instalamos localmente el Session Manager Plugin y ejecutamos:

```bash
aws ssm start-session \
  --target <INSTANCE_ID> \
  --profile terraform-lab \
  --region eu-west-1
```

Obtuvimos:

```text
Starting session with SessionId: ...
$
```

### 🧠 ¿Qué aprendimos?

Podemos administrar la EC2 sin:

```text
❌ SSH público
❌ Puerto 22 abierto
❌ Key Pair
```

La arquitectura queda:

```text
Mac
 │
 │ AWS CLI
 │ Session Manager Plugin
 ▼
AWS Systems Manager
 │
 ▼
SSM Agent
 │
 ▼
EC2
```

Esto reduce la superficie de exposición de la instancia.

---

## 05.18 — Usuario `ssm-user`

Dentro de EC2 ejecutamos:

```bash
whoami
```

Resultado:

```text
ssm-user
```

### 🧠 ¿Qué aprendimos?

Session Manager crea/utiliza un usuario específico para la sesión.

No estábamos entrando mediante:

```text
ubuntu + SSH
```

sino mediante:

```text
ssm-user + Systems Manager
```

Por eso inicialmente:

```bash
cat /home/ubuntu/terraform-lab.txt
```

devolvió:

```text
Permission denied
```

Mientras:

```bash
sudo cat /home/ubuntu/terraform-lab.txt
```

funcionó correctamente.

También diferenciamos:

```text
Permission denied
```

de:

```text
No such file or directory
```

El primero indica un problema de permisos.

El segundo indicaría que la ruta o archivo no existe.

---

## 05.19 — Verificación del User Data

Ejecutamos:

```bash
sudo cat /home/ubuntu/terraform-lab.txt
```

Resultado:

```text
Terraform DevSecOps Platform
EC2 configured automatically using Terraform User Data
```

### 🧠 ¿Qué aprendimos?

Esto confirmó el flujo completo:

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
    ↓
terraform-lab.txt
```

La configuración se ejecutó automáticamente durante el arranque de la instancia.

---

## 05.20 — Verificación de SSM Agent

Comprobamos:

```bash
sudo systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service --no-pager
```

Resultado:

```text
Active: active (running)
```

También observamos el proceso:

```text
ssm-session-worker
```

correspondiente a nuestra sesión activa.

### 🧠 ¿Qué aprendimos?

No solamente comprobamos desde AWS que la instancia estaba `Online`.

También verificamos desde dentro de Ubuntu que `amazon-ssm-agent` estaba ejecutándose correctamente.

---

## 05.21 — Terraform State

Terraform mantiene la relación entre una dirección lógica como:

```text
aws_instance.devsecops
```

y el recurso real creado en AWS.

Conceptualmente:

```text
Terraform Configuration
         │
         ▼
aws_instance.devsecops
         │
         ▼
Terraform State
         │
         ▼
EC2 real en AWS
```

### 🧠 ¿Qué aprendimos?

Terraform necesita saber qué recurso real corresponde con cada recurso declarado en nuestra configuración.

El State mantiene esa relación y otra información necesaria para administrar la infraestructura.

Por eso no debemos perderlo ni publicarlo indiscriminadamente.

Más adelante evolucionaremos desde State local hacia **Remote State**.

---

## 05.22 — Validación final e idempotencia

Después de terminar todas las pruebas ejecutamos:

```bash
terraform plan
```

Terraform refrescó los recursos existentes y respondió:

```text
No changes. Your infrastructure matches the configuration.
```

### 🧠 ¿Qué aprendimos?

Nuestra situación final es:

```text
Terraform Configuration
        =
Terraform State
        =
Infraestructura real
```

No hay cambios pendientes.

Terraform trabaja de forma declarativa: indicamos el estado deseado y Terraform calcula qué operaciones son necesarias para alcanzarlo.

Si ya estamos en ese estado:

```text
Misma configuración deseada
          ↓
terraform plan
          ↓
No changes
```

---

# 06 — Organización del código

La infraestructura está separada por responsabilidad:

```text
network.tf
│
├── VPC
├── Internet Gateway
├── Public Subnet
├── Private Subnet
├── Route Tables
├── Routes
└── Associations
```

```text
security.tf
│
└── Security Group
```

```text
compute.tf
│
├── Ubuntu AMI Data Source
└── EC2
```

```text
iam.tf
│
├── IAM Role
├── Policy Attachment
└── Instance Profile
```

## 🧠 ¿Qué aprendimos?

Terraform identifica un recurso por su dirección:

```text
aws_instance.devsecops
```

y no por el archivo donde esté escrito.

Mover un bloque entre archivos `.tf` dentro del mismo módulo no cambia automáticamente la dirección del recurso.

---

# 07 — Git y seguridad

`.gitignore` evita subir:

```gitignore
.terraform/

*.tfstate
*.tfstate.*

*.tfvars
*.tfvars.json

crash.log
crash.*.log

override.tf
override.tf.json
*_override.tf
*_override.tf.json

.terraformrc
terraform.rc

.DS_Store
```

Sí versionamos:

```text
*.tf
README.md
.gitignore
.terraform.lock.hcl
user-data.sh
```

## 🧠 ¿Qué aprendimos?

El State puede contener información sensible y no debe almacenarse directamente en un repositorio público.

También aprendimos que:

```text
.terraform.lock.hcl
```

normalmente sí debe versionarse para mantener consistentes las versiones seleccionadas de providers.

---

# 🔄 Flujo de trabajo

```text
          ┌───────────────────────┐
          │  Entender el recurso  │
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
            Verificar AWS CLI
                      ▼
          Diagnosticar errores
                      ▼
             Documentación
                      ▼
               Git commit
```

---

# ⚠️ Regla fundamental

Nunca ejecutar automáticamente:

```bash
terraform apply
```

sin entender primero:

```bash
terraform plan
```

Especialmente:

```text
+     create
~     update in-place
-     destroy
-/+   replacement
```

Si aparece una destrucción que no esperábamos:

```text
STOP
 ↓
Investigar
 ↓
Entender
 ↓
Aplicar solamente cuando sea correcto
```

---

# 🧪 Comandos Terraform utilizados

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
terraform output -raw vpc_id
```

---

# 🧪 Comandos AWS utilizados

Durante las verificaciones utilizamos AWS CLI para consultar:

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
```

También utilizamos:

```bash
aws ssm describe-instance-information
```

para verificar el estado de SSM y:

```bash
aws ssm start-session
```

para acceder a EC2 mediante Session Manager.

---

# 🧠 Conceptos aprendidos hasta ahora

## Terraform

- Infrastructure as Code.
- Configuración declarativa.
- Providers.
- Resources.
- Data Sources.
- `resource` vs `data`.
- Terraform State.
- Dependency Graph.
- Implicit dependencies.
- Resource references.
- Variables.
- Fuentes de valores de variables.
- `terraform.tfvars`.
- Locals.
- Outputs.
- `file()`.
- `path.module`.
- `jsonencode()`.
- `jsondecode()`.
- `(known after apply)`.
- Refactoring.
- `terraform fmt`.
- `terraform validate`.
- `terraform plan`.
- `terraform apply`.
- Update in-place.
- Resource replacement.
- Plan symbols.
- Idempotencia.
- Provider/API validation.

## AWS Networking

- VPC.
- CIDR.
- Public Subnet.
- Private Subnet.
- Availability Zones.
- Internet Gateway.
- Route Tables.
- Routes.
- Default Route.
- Local Route.
- Route Table Associations.
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
- Public IP.
- Private IP.

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
- SSM Managed Instance.
- `ssm-user`.
- Administración sin SSH.
- Diagnóstico de conectividad.

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
├── 01 — Terraform Setup                         ✅
│
├── 02 — Networking                              ✅
│   ├── VPC                                      ✅
│   ├── Public Subnet                            ✅
│   ├── Private Subnet                           ✅
│   ├── Internet Gateway                         ✅
│   ├── Public Route Table                       ✅
│   ├── Public Internet Route                    ✅
│   ├── Public RT Association                    ✅
│   ├── Private Route Table                      ✅
│   ├── Private RT Association                   ✅
│   └── Security Group                           ✅
│
├── Variables / tfvars / locals                  ✅
├── Outputs                                      ✅
├── Code organization                            ✅
├── AWS CLI verification                         ✅
│
├── 05 — Compute / EC2                           ✅
│   ├── Ubuntu AMI Data Source                   ✅
│   ├── EC2 t2.micro                             ✅
│   ├── Public IPv4                              ✅
│   ├── Security Group                           ✅
│   ├── IAM Role                                 ✅
│   ├── AmazonSSMManagedInstanceCore             ✅
│   ├── Instance Profile                         ✅
│   ├── User Data                                ✅
│   ├── SSM Agent                                ✅
│   ├── Session Manager                          ✅
│   ├── Acceso sin SSH                           ✅
│   ├── Troubleshooting SSM                      ✅
│   └── terraform plan → No changes              ✅
│
└── Próximo bloque                               ⏳
```

---

# 🗺️ Roadmap

## ✅ Completado

- [x] Configuración inicial de Terraform.
- [x] Provider AWS.
- [x] VPC.
- [x] Diseño CIDR.
- [x] Public Subnet.
- [x] Private Subnet.
- [x] Internet Gateway.
- [x] Public Route Table.
- [x] Ruta `0.0.0.0/0`.
- [x] Route Table Associations.
- [x] Security Group.
- [x] Variables.
- [x] `terraform.tfvars`.
- [x] Locals.
- [x] Outputs.
- [x] Organización del código.
- [x] `.gitignore`.
- [x] AWS CLI.
- [x] AMI mediante Data Source.
- [x] EC2.
- [x] IAM Role.
- [x] Trust Policy.
- [x] Policy Attachment.
- [x] Instance Profile.
- [x] AWS Systems Manager.
- [x] Session Manager.
- [x] Acceso sin SSH.
- [x] User Data.
- [x] Diagnóstico real de conectividad.
- [x] Verificación de SSM Agent.
- [x] Validación final mediante `terraform plan`.
- [x] Documentación de Compute.

---

# 🔐 Arquitectura actual

```text
                              INTERNET
                                  │
                                  ▼
                         Internet Gateway
                                  │
                                  ▼
                         VPC 10.0.0.0/16
                                  │
                ┌─────────────────┴─────────────────┐
                │                                   │
         PUBLIC SUBNET                       PRIVATE SUBNET
          10.0.1.0/24                         10.0.2.0/24
                │
                ▼
              EC2
         Ubuntu 24.04
           t2.micro
                │
        ┌───────┴────────┐
        │                │
 Security Group     Instance Profile
        │                │
 Ingress: none       IAM Role
 Egress: allowed         │
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
                    sin SSH/22
```

---

# 🚀 Evolución del proyecto

La arquitectura actual sigue siendo una base sobre la que construiremos progresivamente una plataforma más completa.

```text
                    ┌───────────────────┐
                    │      GitHub       │
                    └─────────┬─────────┘
                              │
                         CI/CD futuro
                              │
                              ▼
                    ┌───────────────────┐
                    │     Terraform     │
                    └─────────┬─────────┘
                              │
                              ▼
                         AWS Platform
                              │
              ┌───────────────┴───────────────┐
              │                               │
          Networking                       Compute
              │                               │
      ┌───────┴───────┐                      ▼
      │               │                     EC2
 Public Subnet   Private Subnet               │
                                              ▼
                                             SSM
```

El objetivo final será disponer de un proyecto práctico que combine:

**Terraform + AWS + Infrastructure as Code + Automation + CI/CD + DevSecOps**

manteniendo siempre una regla:

> **No añadir tecnología por añadirla. Cada componente debe resolver una necesidad concreta y debemos entender por qué existe.**
