# Plataforma DevSecOps en AWS con Terraform

Proyecto práctico para aprender **Terraform sobre AWS** construyendo una infraestructura real de forma progresiva y entendiendo qué hace cada recurso antes de avanzar al siguiente.

El objetivo no es únicamente desplegar infraestructura, sino aprender un flujo de trabajo profesional con **Infrastructure as Code (IaC)**:

**entender → implementar → formatear → validar → planificar → aplicar → verificar → documentar → versionar**

> 🚧 Estado actual: **Networking completado**.  
> ➡️ Próximo bloque: **Compute / EC2**.

---

## 🎯 Objetivos del proyecto

Este proyecto tiene como objetivos:

- Aprender Terraform de forma práctica.
- Construir infraestructura AWS desde cero.
- Entender las dependencias entre recursos.
- Aprender arquitectura básica de redes en AWS.
- Aplicar buenas prácticas de organización.
- Evitar valores hardcodeados.
- Utilizar variables, locals y outputs.
- Validar cada cambio antes de modificar AWS.
- Verificar la infraestructura mediante AWS CLI.
- Versionar Infrastructure as Code mediante Git.
- Aplicar progresivamente buenas prácticas de seguridad.
- Evolucionar hacia una plataforma orientada a **DevOps / DevSecOps y CI/CD**.

---

# 🧰 Tecnologías

Actualmente se utilizan:

| Tecnología | Uso |
|---|---|
| Terraform | Infrastructure as Code |
| AWS | Cloud Provider |
| AWS CLI | Verificación de infraestructura |
| Git | Control de versiones |
| GitHub | Repositorio remoto |

Región AWS utilizada:

```text
eu-west-1
```

Availability Zone utilizada actualmente:

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
│
├── outputs.tf
│
├── README.md
└── .gitignore
```

Terraform interpreta todos los archivos `.tf` del mismo directorio como una única configuración.

Por tanto, **no es obligatorio tener todos los recursos dentro de `main.tf`**.

Los archivos se han separado por responsabilidad para facilitar el mantenimiento y permitir que el proyecto pueda crecer de forma ordenada.

---

# 01 — Configuración inicial de Terraform

Antes de crear infraestructura se preparó el proyecto Terraform.

La configuración se separó en distintos archivos para evitar concentrar todo el código en un único fichero.

## Archivos principales

### `versions.tf`

Contiene los requisitos relacionados con Terraform y los providers utilizados por el proyecto.

### `providers.tf`

Configura el provider de AWS.

### `variables.tf`

Declara las variables de entrada utilizadas por nuestra infraestructura.

### `terraform.tfvars`

Contiene los valores concretos utilizados en nuestro entorno.

### `locals.tf`

Contiene valores internos reutilizables.

### `network.tf`

Contiene actualmente los recursos relacionados con networking.

### `security.tf`

Contiene los recursos relacionados con seguridad.

### `outputs.tf`

Expone información útil de la infraestructura desplegada.

---

## 🧠 ¿Qué aprendimos?

Terraform carga conjuntamente todos los archivos `.tf` existentes en el mismo directorio.

Por ejemplo:

```text
network.tf
security.tf
outputs.tf
```

no son tres proyectos diferentes.

Terraform los interpreta como:

```text
Una única configuración Terraform
```

Esto permite organizar el código por responsabilidad sin modificar el comportamiento de la infraestructura.

---

## ✅ Al finalizar este punto

Utilizamos el flujo básico:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Antes de ejecutar cualquier cambio sobre AWS, revisamos siempre el resultado de:

```bash
terraform plan
```

---

# 02 — Networking

La primera infraestructura construida ha sido la capa de red sobre la que posteriormente desplegaremos Compute, IAM y el resto de servicios.

---

# 🏗️ Arquitectura actual

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
                 │                                 │
        PUBLIC SUBNET                       PRIVATE SUBNET
         10.0.1.0/24                         10.0.2.0/24
         eu-west-1a                           eu-west-1a
                 │                                 │
                 │                                 │
      Public Route Table                 Private Route Table
                 │                                 │
       ┌─────────┴─────────┐                       │
       │                   │                       │
10.0.0.0/16 → local   0.0.0.0/0 → IGW      10.0.0.0/16 → local
```

---

# 02.1 — VPC

Se creó la red principal del proyecto utilizando una VPC.

CIDR:

```text
10.0.0.0/16
```

Configuración:

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

---

## 🧠 ¿Qué aprendimos?

La VPC representa nuestra red privada dentro de AWS.

El CIDR:

```text
10.0.0.0/16
```

nos proporciona un espacio amplio que posteriormente podemos dividir en subredes.

También aprendimos a evitar IDs hardcodeados.

En lugar de escribir manualmente el ID de una VPC:

```text
vpc-xxxxxxxx
```

otros recursos utilizan:

```hcl
aws_vpc.main.id
```

Terraform puede construir así automáticamente las dependencias entre recursos.

Por ejemplo:

```text
VPC
 │
 ├── Subnet
 │
 ├── Internet Gateway
 │
 ├── Route Tables
 │
 └── Security Group
```

---

## ✅ Al finalizar este punto

Ejecutamos:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Y verificamos que la VPC existía realmente en AWS.

También utilizamos AWS CLI para comprobar la infraestructura directamente.

---

# 02.2 — Public Subnet

Se creó una subnet destinada a recursos que puedan necesitar conectividad pública.

CIDR:

```text
10.0.1.0/24
```

Availability Zone:

```text
eu-west-1a
```

Terraform:

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

---

## 🧠 ¿Qué aprendimos?

Una subnet **no es pública simplemente porque se llame `public`**.

El nombre:

```text
public-subnet
```

es únicamente una etiqueta.

Para que una subnet tenga conectividad directa hacia Internet necesitamos, entre otras cosas:

```text
Subnet
   │
   ▼
Route Table
   │
   ▼
0.0.0.0/0
   │
   ▼
Internet Gateway
```

También aprendimos que un `/24` contiene:

```text
256 direcciones IPv4
```

AWS reserva 5 direcciones en cada subnet.

Por tanto quedan:

```text
251 direcciones utilizables
```

---

## ✅ Al finalizar este punto

Ejecutamos:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Después verificamos que:

- La subnet pertenecía a nuestra VPC.
- Tenía el CIDR correcto.
- Estaba en `eu-west-1a`.

---

# 02.3 — Private Subnet

También se creó una subnet privada.

CIDR:

```text
10.0.2.0/24
```

Availability Zone:

```text
eu-west-1a
```

Terraform:

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

---

## 🧠 ¿Qué aprendimos?

La diferencia entre nuestras subnets no depende principalmente de su nombre.

La diferencia fundamental estará en el **routing**.

La subnet privada actualmente NO dispone de:

```text
0.0.0.0/0 → Internet Gateway
```

Su Route Table solamente contiene la ruta interna de la VPC.

En el futuro, si necesitamos que recursos privados puedan salir a Internet sin quedar directamente expuestos, estudiaremos la solución apropiada, como NAT u otras alternativas según la arquitectura.

---

## ✅ Al finalizar este punto

Ejecutamos:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Y comprobamos que teníamos:

```text
VPC 10.0.0.0/16
│
├── Public Subnet
│   └── 10.0.1.0/24
│
└── Private Subnet
    └── 10.0.2.0/24
```

---

# 02.4 — Internet Gateway

Creamos un Internet Gateway asociado a nuestra VPC.

Terraform:

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${local.name_prefix}-igw"
    Project = var.project_name
  }
}
```

---

## 🧠 ¿Qué aprendimos?

El Internet Gateway proporciona un punto de conexión entre nuestra VPC e Internet.

Pero crear un IGW **no convierte automáticamente nuestras subnets en públicas**.

Necesitamos también configurar correctamente las rutas.

El flujo será:

```text
Internet
   │
   ▼
Internet Gateway
   │
   ▼
VPC
   │
   ▼
Route Table
   │
   ▼
Public Subnet
```

---

## ✅ Al finalizar este punto

Ejecutamos:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Y verificamos que el Internet Gateway estaba asociado correctamente a nuestra VPC.

---

# 02.5 — Public Route Table

Creamos una Route Table específica para la subnet pública.

Terraform:

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${local.name_prefix}-public-rt"
    Project = var.project_name
  }
}
```

AWS añade automáticamente la ruta local correspondiente a nuestra VPC:

```text
10.0.0.0/16 → local
```

---

## 🧠 ¿Qué aprendimos?

La ruta:

```text
10.0.0.0/16 → local
```

permite el routing interno dentro de la VPC.

Por ejemplo:

```text
10.0.1.x
    │
    ▼
10.0.2.x
```

puede ser enrutado internamente por la VPC.

Esto no significa que cualquier comunicación vaya a estar permitida automáticamente, ya que también intervienen controles como:

- Security Groups.
- Network ACLs.

---

## ✅ Al finalizar este punto

Ejecutamos:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Y comprobamos la tabla creada antes de añadirle acceso hacia Internet.

---

# 02.6 — Public Internet Route

Añadimos una ruta hacia Internet:

```text
0.0.0.0/0 → Internet Gateway
```

Terraform:

```hcl
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
```

---

## 🧠 ¿Qué aprendimos?

`0.0.0.0/0` representa cualquier destino IPv4 que no coincida con una ruta más específica.

Nuestra tabla queda conceptualmente:

```text
DESTINATION       TARGET

10.0.0.0/16       local
0.0.0.0/0         Internet Gateway
```

Por tanto:

```text
Tráfico interno
      │
      ▼
    local

Tráfico externo
      │
      ▼
Internet Gateway
```

---

## ✅ Al finalizar este punto

Aplicamos los cambios y verificamos mediante AWS CLI que:

```text
10.0.0.0/16 → local
0.0.0.0/0   → IGW
```

estaban presentes en la Route Table pública.

---

# 02.7 — Public Route Table Association

Crear una Route Table no es suficiente.

Tenemos que asociarla a la subnet que debe utilizarla.

Terraform:

```hcl
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

---

## 🧠 ¿Qué aprendimos?

La relación completa es:

```text
Public Subnet
      │
      ▼
Public Route Table
      │
      ▼
0.0.0.0/0
      │
      ▼
Internet Gateway
      │
      ▼
Internet
```

La asociación determina qué tabla de rutas utiliza la subnet.

---

## ✅ Al finalizar este punto

Verificamos mediante AWS CLI:

- La asociación.
- La subnet asociada.
- La Route Table utilizada.
- Las rutas existentes.

---

# 02.8 — Private Route Table

Creamos una Route Table independiente para la subnet privada.

Terraform:

```hcl
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${local.name_prefix}-private-rt"
    Project = var.project_name
  }
}
```

Actualmente contiene únicamente:

```text
10.0.0.0/16 → local
```

---

## 🧠 ¿Qué aprendimos?

Separar las Route Tables nos permite aplicar políticas de routing diferentes.

Tenemos:

```text
PUBLIC
10.0.0.0/16 → local
0.0.0.0/0   → IGW
```

frente a:

```text
PRIVATE
10.0.0.0/16 → local
```

La subnet privada **no tiene una ruta directa al Internet Gateway**.

---

## ✅ Al finalizar este punto

Aplicamos la configuración y verificamos que la tabla privada no tenía accidentalmente:

```text
0.0.0.0/0 → IGW
```

---

# 02.9 — Private Route Table Association

Asociamos la subnet privada con su propia Route Table.

Terraform:

```hcl
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

---

## 🧠 ¿Qué aprendimos?

Ahora ambas subnets tienen explícitamente su propia tabla:

```text
VPC
│
├── Public Subnet
│       │
│       ▼
│   Public RT
│       │
│       └── 0.0.0.0/0 → IGW
│
└── Private Subnet
        │
        ▼
    Private RT
        │
        └── local only
```

---

## ✅ Al finalizar este punto

AWS CLI confirmó que:

```text
Private Route Table
├── 10.0.0.0/16 → local
└── Private Subnet asociada
```

y que no existía ninguna salida directa hacia el Internet Gateway.

---

# 02.10 — Main Route Table creada por AWS

Durante las verificaciones encontramos una tercera Route Table que no habíamos definido explícitamente con Terraform.

Esto es normal.

AWS crea automáticamente una **Main Route Table** cuando se crea una VPC.

---

## 🧠 ¿Qué aprendimos?

Encontrar un recurso en AWS que no recordamos haber definido no significa necesariamente que Terraform haya hecho algo incorrectamente.

Algunos recursos forman parte del comportamiento automático de AWS.

Nuestras subnets están asociadas explícitamente a:

```text
Public Subnet
      ↓
Public Route Table
```

y:

```text
Private Subnet
      ↓
Private Route Table
```

por lo que no dependen de la Main Route Table para su routing actual.

---

## ✅ Al finalizar este punto

Consultamos las Route Tables de toda la VPC mediante AWS CLI y verificamos qué tabla estaba asociada a cada subnet.

---

# 02.11 — Security Group

Creamos un Security Group base asociado a nuestra VPC.

Terraform:

```hcl
resource "aws_security_group" "terraform_lab" {
  name        = "${local.name_prefix}-sg"
  description = "security group for terraform learning project"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${local.name_prefix}-sg"
    Project = var.project_name
  }
}
```

Todavía no hemos añadido las reglas definitivas.

Las iremos incorporando cuando tengamos recursos que realmente necesiten tráfico específico.

---

## 🧠 ¿Qué aprendimos?

Un Security Group pertenece a una:

```text
VPC
```

No pertenece directamente a una subnet.

Posteriormente podremos asociarlo a recursos como EC2.

También aprendimos algo muy importante sobre Terraform.

Al modificar determinados atributos de un recurso Terraform puede indicar:

```text
-/+
```

Esto significa:

```text
destroy
   +
create replacement
```

Es decir, Terraform necesita sustituir el recurso.

Esto nos enseñó que **no debemos ejecutar `terraform apply` sin revisar previamente el plan**.

---

## ⚠️ Lección importante

Si vemos:

```text
-/+
```

o:

```text
Plan: X to add, X to change, X to destroy
```

y no esperábamos destrucciones:

**paramos y revisamos el plan antes de aplicar.**

---

## ✅ Al finalizar este punto

Ejecutamos:

```bash
terraform fmt
terraform validate
terraform plan
```

Revisamos el reemplazo antes de aceptarlo y posteriormente comprobamos el nuevo Security Group.

---

# 03 — Variables y reutilización

Una vez construida la red comenzamos a refactorizar el código.

El objetivo era evitar valores repetidos y hardcodeados.

---

# 03.1 — variables.tf

Las variables definen las entradas que necesita nuestra configuración.

Ejemplo:

```hcl
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}
```

Actualmente tenemos variables como:

```text
project_name
vpc_cidr
public_subnet_cidr
private_subnet_cidr
availability_zone
```

---

## 🧠 ¿Qué aprendimos?

Una variable puede entenderse como:

```text
¿Qué dato necesita mi infraestructura?
```

Por ejemplo:

```hcl
variable "vpc_cidr"
```

declara que necesitamos un CIDR.

Después podemos utilizar:

```hcl
var.vpc_cidr
```

dentro de nuestros recursos.

---

## ✅ Al finalizar este punto

Ejecutamos:

```bash
terraform fmt
terraform validate
terraform plan
```

Terraform respondió:

```text
No changes. Your infrastructure matches the configuration.
```

Esto fue importante porque demostramos que podemos **refactorizar el código sin modificar los recursos reales de AWS**.

---

# 03.2 — terraform.tfvars

`terraform.tfvars` proporciona valores concretos para nuestras variables.

Actualmente utilizamos valores como:

```hcl
project_name = "terraform-aws-devsecops-platform"

vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

availability_zone = "eu-west-1a"
```

Conceptualmente:

```text
terraform.tfvars
       │
       ▼
variables.tf
       │
       ▼
var.xxx
       │
       ▼
Terraform Resources
```

---

## 🧠 ¿Qué aprendimos?

Una forma sencilla de recordarlo:

```text
variables.tf
    ↓
¿Qué necesito?
```

```text
terraform.tfvars
    ↓
¿Qué valor voy a utilizar?
```

Por ejemplo:

```text
variables.tf
    ↓
Necesito vpc_cidr
```

y:

```text
terraform.tfvars
    ↓
vpc_cidr = "10.0.0.0/16"
```

---

## 🔐 Seguridad

Actualmente `terraform.tfvars` está ignorado mediante `.gitignore`.

Esto evita que configuración local termine accidentalmente en Git.

Más adelante podemos proporcionar:

```text
terraform.tfvars.example
```

para documentar qué variables necesita el proyecto sin publicar valores que no queramos versionar.

---

## ✅ Al finalizar este punto

Volvimos a ejecutar:

```bash
terraform fmt
terraform validate
terraform plan
```

Resultado:

```text
No changes. Your infrastructure matches the configuration.
```

---

# 03.3 — locals.tf

Creamos un valor local para reutilizar el prefijo de nombres.

```hcl
locals {
  name_prefix = "terraform-lab"
}
```

Podemos utilizarlo así:

```hcl
Name = "${local.name_prefix}-vpc"
```

o:

```hcl
Name = "${local.name_prefix}-public-subnet"
```

---

## 🧠 ¿Qué aprendimos?

La diferencia principal entre variables y locals:

```text
var.xxx
   │
   └── entrada configurable
```

frente a:

```text
local.xxx
   │
   └── valor interno/reutilizable
```

Ejemplo:

```hcl
var.vpc_cidr
```

puede cambiar dependiendo del entorno.

Mientras:

```hcl
local.name_prefix
```

lo utilizamos internamente para evitar repetir nombres.

---

## ✅ Al finalizar este punto

Ejecutamos:

```bash
terraform fmt
terraform validate
terraform plan
```

Terraform volvió a indicar:

```text
No changes. Your infrastructure matches the configuration.
```

---

# 04 — Outputs

Creamos `outputs.tf` para exponer información útil después de desplegar la infraestructura.

Actualmente mostramos:

```text
vpc_id
public_subnet_id
private_subnet_id
internet_gateway_id
public_route_table_id
private_route_table_id
security_group_id
```

Ejemplo:

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
```

---

## 🧠 ¿Qué aprendimos?

Los outputs pueden entenderse como:

```text
INPUTS                      OUTPUTS

terraform.tfvars               ▲
      │                        │
      ▼                        │
variables.tf                   │
      │                        │
      ▼                        │
Terraform ──────── AWS ────────┘
```

Las variables introducen información.

Los outputs extraen información útil de la infraestructura resultante.

---

## Consultar outputs

Todos:

```bash
terraform output
```

Uno concreto:

```bash
terraform output vpc_id
```

Para utilizarlo fácilmente desde scripts o CI/CD:

```bash
terraform output -raw vpc_id
```

Esto será especialmente útil posteriormente para automatizaciones.

---

## ✅ Al finalizar este punto

Ejecutamos:

```bash
terraform apply
```

Terraform indicó:

```text
Resources: 0 added, 0 changed, 0 destroyed.
```

porque añadir outputs no modificaba nuestra infraestructura.

Después comprobamos:

```bash
terraform output
```

y Terraform devolvió correctamente los identificadores de nuestros recursos.

---

# 05 — Organización del código

Inicialmente los recursos estaban concentrados en:

```text
main.tf
```

Posteriormente reorganizamos el proyecto.

Actualmente:

```text
network.tf
│
├── VPC
├── Internet Gateway
├── Public Subnet
├── Private Subnet
├── Public Route Table
├── Public Internet Route
├── Public Route Table Association
├── Private Route Table
└── Private Route Table Association
```

y:

```text
security.tf
│
└── Security Group
```

---

## 🧠 ¿Qué aprendimos?

Terraform no identifica un recurso por el archivo donde está escrito.

Por ejemplo:

```hcl
resource "aws_security_group" "terraform_lab"
```

tiene la dirección:

```text
aws_security_group.terraform_lab
```

Mover ese bloque:

```text
main.tf
   ↓
security.tf
```

no cambia su dirección dentro de Terraform.

Por eso pudimos reorganizar los archivos sin destruir la infraestructura.

---

## ✅ Al finalizar este punto

Después de mover los recursos ejecutamos:

```bash
terraform fmt
terraform validate
terraform plan
```

Resultado:

```text
Success! The configuration is valid.
```

y:

```text
No changes. Your infrastructure matches the configuration.
```

Esto confirmó que la reorganización del código **no había modificado AWS**.

---

# 06 — Git y seguridad del repositorio

También configuramos `.gitignore` para evitar subir archivos que no deben almacenarse en Git.

Entre ellos:

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

---

## 🧠 ¿Por qué no versionamos terraform.tfstate?

Terraform State mantiene información sobre la relación entre:

```text
Terraform configuration
        ↕
Terraform State
        ↕
AWS resources
```

Puede contener información que no queremos publicar.

Por eso:

```text
terraform.tfstate
```

y sus backups no deben subirse al repositorio público.

Más adelante estudiaremos **Remote State**, que es especialmente importante cuando Terraform se utiliza en equipos y pipelines CI/CD.

---

## 🧠 ¿Qué sí versionamos?

Sí queremos almacenar:

```text
*.tf
README.md
.gitignore
.terraform.lock.hcl
```

El lock file:

```text
.terraform.lock.hcl
```

normalmente **sí debe versionarse**.

Ayuda a mantener consistentes las versiones de los providers utilizadas por el proyecto.

---

# 🔄 Flujo de trabajo utilizado

Durante el proyecto estamos siguiendo este proceso:

```text
          ┌───────────────────────┐
          │  Entender el recurso  │
          └───────────┬───────────┘
                      │
                      ▼
          ┌───────────────────────┐
          │  Escribir Terraform   │
          └───────────┬───────────┘
                      │
                      ▼
             terraform fmt
                      │
                      ▼
           terraform validate
                      │
                      ▼
             terraform plan
                      │
                      ▼
              REVISAR PLAN
                      │
                      ▼
             terraform apply
                      │
                      ▼
           Verificar en AWS
                      │
                      ▼
            Verificar AWS CLI
                      │
                      ▼
             Documentación
                      │
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

Especialmente si aparecen operaciones como:

```text
destroy
```

o:

```text
-/+
```

Si Terraform quiere destruir algo que no esperábamos:

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

# 🧪 Comandos utilizados

Inicialización:

```bash
terraform init
```

Formatear:

```bash
terraform fmt
```

Validar:

```bash
terraform validate
```

Planificar:

```bash
terraform plan
```

Aplicar:

```bash
terraform apply
```

Consultar outputs:

```bash
terraform output
```

Consultar un output concreto:

```bash
terraform output vpc_id
```

Obtener únicamente su valor:

```bash
terraform output -raw vpc_id
```

---

# 🧠 Conceptos aprendidos hasta ahora

Durante esta primera fase hemos trabajado con:

### Terraform

- Infrastructure as Code.
- Providers.
- Resources.
- Terraform State.
- Dependency Graph.
- Resource references.
- Variables.
- `terraform.tfvars`.
- Local values.
- Outputs.
- Refactoring.
- Terraform formatting.
- Terraform validation.
- Terraform plans.
- Terraform apply.

### AWS Networking

- VPC.
- CIDR.
- Public Subnets.
- Private Subnets.
- Availability Zones.
- Internet Gateway.
- Route Tables.
- Routes.
- Default route.
- Local route.
- Route Table Associations.
- Main Route Table.
- Security Groups.

### DevOps

- Git.
- GitHub.
- `.gitignore`.
- Infrastructure versioning.
- Incremental changes.
- Validation before deployment.
- AWS CLI verification.
- Documentation as part of the development process.

---

# 📊 Estado actual

```text
Terraform AWS DevSecOps Platform
│
├── 01 — Terraform Setup                 ✅
│
├── 02 — Networking                      ✅
│   │
│   ├── VPC                              ✅
│   ├── Public Subnet                    ✅
│   ├── Private Subnet                   ✅
│   ├── Internet Gateway                 ✅
│   ├── Public Route Table               ✅
│   ├── Public Internet Route            ✅
│   ├── Public RT Association            ✅
│   ├── Private Route Table              ✅
│   ├── Private RT Association           ✅
│   └── Security Group base              ✅
│
├── Variables                            ✅
├── terraform.tfvars                     ✅
├── Locals                               ✅
├── Outputs                              ✅
├── Code organization                    ✅
├── AWS CLI verification                 ✅
│
└── 03 — Compute / EC2                   ⏳ NEXT
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
- [x] Ruta `0.0.0.0/0` hacia Internet.
- [x] Public Route Table Association.
- [x] Private Route Table.
- [x] Private Route Table Association.
- [x] Verificación del routing.
- [x] Security Group base.
- [x] Variables.
- [x] `terraform.tfvars`.
- [x] Locals.
- [x] Outputs.
- [x] Organización del código.
- [x] `.gitignore`.
- [x] Verificación mediante AWS CLI.
- [x] Documentación inicial.

---

# ⏭️ Próximo bloque — Compute / EC2

El siguiente objetivo será desplegar nuestra primera carga de trabajo sobre la infraestructura de red.

Trabajaremos progresivamente con:

- [ ] Diseño de la instancia EC2.
- [ ] Selección de AMI.
- [ ] Instance Type.
- [ ] Variables de Compute.
- [ ] `compute.tf`.
- [ ] EC2 dentro de la Public Subnet.
- [ ] Direccionamiento IPv4 público.
- [ ] Reglas del Security Group.
- [ ] Acceso seguro.
- [ ] SSH vs AWS Systems Manager.
- [ ] IAM Role.
- [ ] Instance Profile.
- [ ] User Data.
- [ ] Outputs de Compute.
- [ ] Verificación mediante AWS CLI.
- [ ] Validación final.
- [ ] Commit del bloque Compute.
- [ ] Actualización de este README.

---

# 🚀 Evolución del proyecto

La arquitectura actual es solamente la base.

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
      ┌───────┴───────┐                      │
      │               │                      ▼
 Public Subnet   Private Subnet             EC2
```

Esta arquitectura irá evolucionando a medida que avancemos en el proyecto.

El objetivo final será disponer de un proyecto práctico que combine conceptos de:

**Terraform + AWS + Infrastructure as Code + Automation + CI/CD + DevSecOps**

manteniendo siempre una regla:

> **No añadir tecnología por añadirla. Cada componente debe resolver una necesidad concreta y debemos entender por qué existe.**