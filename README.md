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
> Networking + Compute/EC2 completados.\
> 🔐 EC2 administrada mediante **AWS Systems Manager Session Manager**,
> sin SSH público ni puerto 22 abierto.\
> ☁️ El State del proyecto principal está almacenado remotamente en
> **Amazon S3**, con cifrado, versionado y locking.

------------------------------------------------------------------------

# 🎯 Objetivos del proyecto

-   Aprender Terraform de forma práctica.
-   Preparar conceptos relevantes para Terraform Associate.
-   Construir infraestructura AWS desde cero.
-   Comprender Infrastructure as Code y configuración declarativa.
-   Trabajar con providers, resources y data sources.
-   Utilizar variables, locals y outputs.
-   Evitar valores hardcodeados.
-   Entender dependencias implícitas y el Dependency Graph.
-   Comprender Terraform State y Remote State.
-   Configurar un backend remoto en Amazon S3.
-   Comprender State Locking, versionado y cifrado.
-   Diseñar networking básico en AWS.
-   Desplegar Compute mediante EC2.
-   Administrar EC2 mediante AWS Systems Manager.
-   Automatizar configuración mediante User Data.
-   Validar cambios antes de modificar AWS.
-   Verificar infraestructura mediante AWS CLI.
-   Diagnosticar problemas reales de infraestructura.
-   Versionar Infrastructure as Code mediante Git.
-   Evolucionar hacia una plataforma DevOps / DevSecOps y CI/CD.

------------------------------------------------------------------------

# 🧰 Tecnologías

  Tecnología                Uso
  ------------------------- ------------------------------
  Terraform                 Infrastructure as Code
  AWS                       Cloud Provider
  Amazon VPC                Networking
  Amazon EC2                Compute
  Amazon S3                 Remote Terraform State
  AWS IAM                   Roles y permisos
  AWS Systems Manager       Administración remota segura
  AWS CLI                   Verificación y diagnóstico
  Ubuntu Server 24.04 LTS   Sistema operativo EC2
  Git                       Control de versiones
  GitHub                    Repositorio remoto

**Región AWS:** `eu-west-1`\
**Availability Zone actual:** `eu-west-1a`

------------------------------------------------------------------------

# 🗺️ Roadmap

``` text
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
     ├── count / for_each / for
     ├── dynamic / conditionals / functions
     ├── depends_on
     ├── lifecycle
     ├── import / moved
     └── refactoring

06+ — DevSecOps
     ├── CI/CD
     ├── Security Scanning
     ├── Quality Gates
     ├── Hardened Images
     └── Automatización
```

------------------------------------------------------------------------

# 📁 Estructura actual

``` text
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
**una única configuración**. El nombre y orden de los archivos no
determina el orden de creación; Terraform utiliza su **Dependency
Graph**.

------------------------------------------------------------------------

# 01 --- Fundamentos de Terraform

## 01.1 --- Organización

Separar archivos por responsabilidad mejora la mantenibilidad:

``` text
network.tf   → Networking
security.tf  → Security Groups
compute.tf   → EC2
iam.tf       → IAM
outputs.tf   → Outputs
backend.tf   → Backend
```

Terraform identifica un recurso por su dirección, por ejemplo:

``` text
aws_instance.devsecops
```

y no por el fichero donde esté escrito.

### 🧠 ¿Qué aprendimos?

Mover un bloque entre archivos `.tf` dentro del mismo módulo no cambia
por sí solo su dirección. Terraform determina las dependencias mediante
referencias entre objetos.

------------------------------------------------------------------------

## 01.2 --- Provider vs Backend

El **provider** permite comunicarse con una plataforma:

``` text
Terraform → AWS Provider → AWS API → AWS
```

El **backend** determina dónde y cómo se almacena el State:

``` text
Terraform → Backend → State
```

### 🧠 ¿Qué aprendimos?

``` text
Provider → ¿Cómo interactúa Terraform con AWS?
Backend  → ¿Dónde se almacena el State?
```

Son conceptos diferentes.

------------------------------------------------------------------------

## 01.3 --- Resources y Data Sources

Un `resource` representa infraestructura administrada por Terraform:

``` hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}
```

Un `data` consulta información existente:

``` hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  # ...
}
```

### 🧠 ¿Qué aprendimos?

``` text
resource → crear / modificar / eliminar
data     → consultar
```

Un Data Source también puede aparecer en el State, aunque Terraform no
haya creado el objeto consultado.

------------------------------------------------------------------------

## 01.4 --- Variables

Variables utilizadas:

``` text
project_name
vpc_cidr
public_subnet_cidr
private_subnet_cidr
availability_zone
instance_type
```

Ejemplo:

``` hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
```

Los valores pueden proceder de diferentes fuentes:

``` text
default
terraform.tfvars
*.auto.tfvars
-var
-var-file
TF_VAR_...
```

### 🧠 ¿Qué aprendimos?

`variables.tf` declara qué entradas existen; `terraform.tfvars` puede
proporcionar sus valores.

------------------------------------------------------------------------

## 01.5 --- Locals

``` hcl
locals {
  name_prefix = "terraform-lab"
}
```

``` text
var.xxx   → entrada configurable
local.xxx → valor interno reutilizable
```

------------------------------------------------------------------------

## 01.6 --- Outputs

Ejemplos actuales:

``` text
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

Consulta:

``` bash
terraform output
terraform output ec2_instance_id
terraform output -raw ec2_instance_id
```

### 🧠 ¿Qué aprendimos?

Los outputs exponen información útil de la infraestructura y pueden ser
consumidos por usuarios, scripts u otras configuraciones.

------------------------------------------------------------------------

## 01.7 --- Comandos básicos

``` bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
terraform output
```

Flujo habitual:

``` text
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

Símbolos principales de `plan`:

``` text
+     create
~     update in-place
-     destroy
-/+   replacement
```

### 🧠 ¿Qué aprendimos?

Nunca debemos ejecutar un `apply` sin comprender previamente qué propone
Terraform.

------------------------------------------------------------------------

## 01.8 --- Plan guardado

También utilizamos:

``` bash
terraform plan -out=tfplan
terraform apply tfplan
```

Esto permite aplicar exactamente el plan previamente calculado.

Los archivos de plan no se versionan en Git.

------------------------------------------------------------------------

## 01.9 --- `(known after apply)`

Durante `terraform plan` algunos atributos pueden aparecer como:

``` text
(known after apply)
```

Significa que Terraform conoce el atributo, pero su valor definitivo
será proporcionado por el provider durante la operación.

No es un error.

------------------------------------------------------------------------

# 02 --- Terraform State y Backend remoto

Este bloque cambia la forma en la que Terraform mantiene el conocimiento
sobre nuestra infraestructura.

## 02.1 --- ¿Qué es Terraform State?

Terraform necesita relacionar las direcciones de nuestra configuración
con los objetos reales.

Ejemplo:

``` text
CONFIGURACIÓN

aws_instance.devsecops
        │
        ▼
      STATE
        │
        ▼
i-0795e372510aec6be
        │
        ▼
      AWS
```

El State contiene el mapeo y metadatos que Terraform necesita para
administrar los objetos.

Nuestro State contiene direcciones como:

``` text
data.aws_ami.ubuntu
aws_iam_instance_profile.ec2_ssm
aws_iam_role.ec2_ssm
aws_iam_role_policy_attachment.ssm_core
aws_instance.devsecops
aws_internet_gateway.main
aws_route.public_internet
aws_route_table.private
aws_route_table.public
aws_route_table_association.private
aws_route_table_association.public
aws_security_group.terraform_lab
aws_subnet.private
aws_subnet.public
aws_vpc.main
```

### 🧠 ¿Qué aprendimos?

La configuración expresa **qué queremos**.

El State mantiene **qué objetos gestiona Terraform y su relación con los
objetos reales**.

AWS representa **lo que existe realmente**.

``` text
Configuration
     ↓
State
     ↓
Provider
     ↓
AWS
```

------------------------------------------------------------------------

## 02.2 --- Comandos de State

Utilizamos:

``` bash
terraform state list
terraform state show aws_instance.devsecops
terraform state show aws_vpc.main
terraform show
```

`terraform state list` muestra las direcciones registradas.

`terraform state show` muestra la información de un objeto concreto.

`terraform show` permite inspeccionar el State de forma legible.

------------------------------------------------------------------------

## 02.3 --- State local

Inicialmente Terraform utilizaba:

``` text
terraform.tfstate
```

en nuestro ordenador.

También podía existir:

``` text
terraform.tfstate.backup
```

como copia anterior.

Arquitectura inicial:

``` text
Mac
│
├── código .tf
└── terraform.tfstate
        │
        ▼
       AWS
```

### Problemas

-   Dependencia de un único ordenador.
-   Mala colaboración en equipo.
-   Riesgo de pérdida.
-   Riesgo de modificaciones concurrentes.
-   El State puede contener información sensible.

Por ello `*.tfstate` está excluido de Git.

------------------------------------------------------------------------

## 02.4 --- `sensitive = true`

Marcar un valor como sensible puede evitar que Terraform lo muestre
normalmente en determinadas salidas.

Pero:

``` text
sensitive = true
```

**NO significa que el dato quede automáticamente cifrado dentro del
State.**

### 🧠 Terraform Associate

Ocultar información de la salida y proteger el almacenamiento del State
son problemas diferentes.

------------------------------------------------------------------------

## 02.5 --- Backend remoto

Decidimos mover el State principal a Amazon S3.

Arquitectura:

``` text
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

``` hcl
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

### 🧠 ¿Qué aprendimos?

El backend no crea infraestructura de aplicación. Configura cómo
Terraform trabaja con su State.

La configuración del backend se procesa durante `terraform init`, antes
del flujo normal de variables, por lo que no se trata como una
configuración de recursos normal basada en `var.*`.

------------------------------------------------------------------------

## 02.6 --- ¿Por qué existe `bootstrap/`?

Apareció un problema:

``` text
Queremos guardar el State en S3
              │
              ▼
Pero el bucket S3 todavía no existe
              │
              ▼
¿Quién crea el bucket?
```

Creamos una configuración Terraform independiente:

``` text
bootstrap/
```

Su única responsabilidad es crear la infraestructura necesaria para
alojar el backend.

``` text
bootstrap/
     │
     ▼
Terraform
     │
     ▼
crea bucket S3
     │
     ▼
El proyecto principal puede usarlo como backend
```

### 🧠 ¿Qué aprendimos?

No podemos almacenar el State principal en un bucket que todavía no
existe.

Por eso separamos el problema:

``` text
BOOTSTRAP
   ↓
crea backend

PROYECTO PRINCIPAL
   ↓
utiliza backend
```

El bootstrap tiene su propio State independiente.

------------------------------------------------------------------------

## 02.7 --- Recursos creados por Bootstrap

El bootstrap creó cuatro recursos:

``` text
aws_s3_bucket.terraform_state
aws_s3_bucket_public_access_block.terraform_state
aws_s3_bucket_server_side_encryption_configuration.terraform_state
aws_s3_bucket_versioning.terraform_state
```

Su configuración incluye:

``` hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name
}
```

### Public Access Block

Impide exponer accidentalmente el bucket públicamente.

### Encryption

Configuramos cifrado en reposo:

``` text
AES256 / SSE-S3
```

### Versioning

S3 conserva versiones anteriores del objeto State.

### 🧠 ¿Qué aprendimos?

El State es información crítica y potencialmente sensible, por lo que
debe protegerse.

------------------------------------------------------------------------

## 02.8 --- Dependencias implícitas en Bootstrap

Ejemplo:

``` hcl
bucket = aws_s3_bucket.terraform_state.id
```

Terraform entiende:

``` text
S3 Bucket
    ↓
Versioning
```

porque el segundo recurso referencia al primero.

No necesitamos añadir `depends_on`.

### 🧠 Terraform Associate

Siempre que una referencia normal expresa correctamente una dependencia,
Terraform puede construirla automáticamente.

------------------------------------------------------------------------

## 02.9 --- Creación del Backend

Dentro de `bootstrap/` ejecutamos:

``` bash
terraform fmt
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Resultado:

``` text
Plan: 4 to add, 0 to change, 0 to destroy.
```

Después:

``` text
Apply complete!
Resources: 4 added, 0 changed, 0 destroyed.
```

Verificamos:

``` bash
terraform state list
```

y el State del bootstrap contenía exclusivamente los cuatro recursos del
backend.

------------------------------------------------------------------------

## 02.10 --- Migración del State

Una vez creado S3 configuramos `backend.tf` en el proyecto principal.

Ejecutamos:

``` bash
terraform init -migrate-state
```

Terraform detectó:

``` text
Backend anterior → local
Backend nuevo    → S3

State local      → existe
State S3         → vacío
```

y preguntó:

``` text
Do you want to copy existing state to the new backend?
```

Respondimos:

``` text
yes
```

### ¿Qué hizo `-migrate-state`?

``` text
ANTES

Mac
└── terraform.tfstate
       │
       └── 15 objetos


MIGRACIÓN
       │
       ▼


DESPUÉS

S3
└── dev/
    └── terraform.tfstate
         │
         └── mismos 15 objetos
```

### 🧠 ¿Qué aprendimos?

**No migramos los recursos AWS.**

La VPC, EC2, IAM, subnets, etc. no se movieron ni se recrearon.

Migramos únicamente el **State** desde el backend local al backend S3.

------------------------------------------------------------------------

## 02.11 --- Verificación de la migración

Después ejecutamos:

``` bash
terraform state list
```

y seguían apareciendo los 15 objetos.

Después:

``` bash
terraform plan
```

Resultado:

``` text
No changes. Your infrastructure matches the configuration.
```

Finalmente verificamos S3:

``` bash
aws s3 ls s3://terraform-aws-devsecops-dt97-state/ --recursive \
  --profile terraform-lab
```

Resultado:

``` text
dev/terraform.tfstate
```

### 🧠 ¿Qué aprendimos?

La migración fue correcta porque:

``` text
Configuration
      =
Remote State
      =
AWS real
```

------------------------------------------------------------------------

## 02.12 --- S3 Versioning

Consultamos:

``` bash
aws s3api list-object-versions \
  --bucket terraform-aws-devsecops-dt97-state \
  --prefix dev/terraform.tfstate \
  --profile terraform-lab
```

S3 mostró un `VersionId` para el State.

Conceptualmente:

``` text
terraform.tfstate
    │
    ├── Version 1
    ├── Version 2
    ├── Version 3
    └── Version actual
```

### 🧠 ¿Qué aprendimos?

Versioning permite conservar historial y facilita recuperación ante
errores.

**Versioning no es State Locking.**

------------------------------------------------------------------------

## 02.13 --- State Locking

Configuramos:

``` hcl
use_lockfile = true
```

El backend S3 puede utilizar:

``` text
dev/terraform.tfstate.tflock
```

durante operaciones que requieren bloquear el State.

Conceptualmente:

``` text
Proceso A
   │
   ▼
adquiere lock 🔒
   │
   ▼
modifica / utiliza State
   │
   ▼
libera lock 🔓
```

Mientras el State está bloqueado, otro proceso no debería modificarlo
simultáneamente.

### 🧠 ¿Qué aprendimos?

``` text
Versioning → historial / recuperación
Locking    → concurrencia
Encryption → confidencialidad en reposo
```

Son tres mecanismos diferentes.

En versiones modernas del backend S3 utilizamos locking nativo mediante
`use_lockfile`. El mecanismo histórico basado en DynamoDB no forma parte
de esta arquitectura.

------------------------------------------------------------------------

## 02.14 --- Tres locks que no debemos confundir

``` text
.terraform.lock.hcl
        │
        └── fija selecciones de providers

State Lock
        │
        └── evita modificaciones concurrentes del State

S3 Versioning
        │
        └── conserva versiones anteriores del State
```

`.terraform.lock.hcl` normalmente sí se versiona en Git.

------------------------------------------------------------------------

## 02.15 --- `terraform state mv`

Conceptualmente:

``` bash
terraform state mv ORIGEN DESTINO
```

permite cambiar la dirección de un objeto dentro del State.

Ejemplo conceptual:

``` text
aws_instance.devsecops
        │
        │ state mv
        ▼
aws_instance.platform
```

El recurso AWS real no tiene por qué recrearse por el simple hecho de
mover su dirección en el State.

------------------------------------------------------------------------

## 02.16 --- `terraform state rm`

``` bash
terraform state rm DIRECCION
```

elimina la asociación del objeto con el State.

``` text
ANTES

Terraform State ─────► EC2


state rm


Terraform State   X   EC2
                      │
                      └── sigue existiendo
```

### 🧠 ¿Qué aprendimos?

`state rm` **no equivale a destruir el recurso real**.

Si la configuración continúa declarando el recurso pero este ya no está
en el State, un plan posterior puede intentar crear otro objeto.

------------------------------------------------------------------------

## 02.17 --- ¿Qué ocurre si perdemos el State?

Los recursos AWS no desaparecen automáticamente.

Lo que perdemos es el conocimiento de Terraform sobre su relación con
esos recursos.

``` text
aws_vpc.main   X   vpc-xxxxxxxx
```

Las primeras defensas son:

``` text
Remote State
+
S3 Versioning
+
Backups / recuperación
```

Si fuera necesario reconstruir asociaciones con infraestructura
existente podemos utilizar mecanismos de importación.

Ejemplo conceptual:

``` bash
terraform import aws_vpc.main vpc-xxxxxxxx
```

``` text
Código
aws_vpc.main
     │
     ├──── import ──── AWS VPC existente
     │
     ▼
   State
```

El import no crea la VPC existente: incorpora su relación al State.

------------------------------------------------------------------------

## 02.18 --- Drift

Si modificamos manualmente AWS:

``` text
Terraform Configuration
t2.micro

AWS real
t3.micro
```

existe una diferencia entre el estado deseado y la infraestructura real.

Terraform puede detectarla al refrescar/planificar.

### 🧠 ¿Qué aprendimos?

``` text
Configuration → estado deseado
State         → objetos gestionados y datos conocidos
Provider      → comunicación con AWS
AWS           → realidad
```

------------------------------------------------------------------------

## 02.19 --- HCP Terraform vs S3

Nuestro modelo:

``` text
Terraform CLI
     │
     ▼
Amazon S3
     │
     ▼
Remote State
```

HCP Terraform puede proporcionar además funcionalidades de plataforma
como ejecución remota, colaboración, integración VCS, workspaces,
gestión de variables y controles centralizados.

S3 por sí mismo es principalmente nuestro almacenamiento remoto del
State; el flujo CI/CD se construye alrededor mediante otras
herramientas.

Ejemplo futuro:

``` text
Developer
    │
    ▼
GitLab / GitHub
    │
    ▼
CI/CD
    │
    ├── terraform fmt
    ├── terraform validate
    ├── terraform plan
    └── terraform apply
             │
             ▼
            AWS

State ─────────────► S3
```

------------------------------------------------------------------------

# 03 --- AWS Networking

## 03.1 --- Arquitectura

``` text
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

------------------------------------------------------------------------

## 03.2 --- VPC

CIDR:

``` text
10.0.0.0/16
```

``` hcl
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

En lugar de hardcodear IDs como `vpc-xxxxxxxx`, utilizamos referencias
como:

``` hcl
aws_vpc.main.id
```

Esto crea dependencias implícitas.

------------------------------------------------------------------------

## 03.3 --- Subnets

Public:

``` text
10.0.1.0/24
```

Private:

``` text
10.0.2.0/24
```

Un `/24` contiene 256 direcciones IPv4; AWS reserva cinco direcciones
por subnet.

### 🧠 ¿Qué aprendimos?

Una subnet no es pública simplemente por llamarse `public`.

Su comportamiento depende especialmente del routing y de la
configuración de los recursos que contiene.

------------------------------------------------------------------------

## 03.4 --- Internet Gateway

``` hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```

Crear un IGW no convierte automáticamente una subnet en pública.

Necesitamos:

``` text
Subnet
  ↓
Route Table
  ↓
0.0.0.0/0
  ↓
Internet Gateway
```

------------------------------------------------------------------------

## 03.5 --- Route Tables

Public Route Table:

``` text
10.0.0.0/16 → local
0.0.0.0/0   → IGW
```

Private Route Table:

``` text
10.0.0.0/16 → local
```

### 🧠 ¿Qué aprendimos?

La ruta `local` permite comunicación dentro de la VPC.

`0.0.0.0/0` representa cualquier destino IPv4 que no coincida con una
ruta más específica.

------------------------------------------------------------------------

## 03.6 --- Associations

Una Route Table debe asociarse a la subnet correspondiente.

``` hcl
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

### 🧠 ¿Qué aprendimos?

Crear una Route Table no basta: debemos determinar qué subnet la
utiliza.

------------------------------------------------------------------------

## 03.7 --- Main Route Table

Durante las verificaciones encontramos una Route Table adicional creada
automáticamente por AWS.

### 🧠 ¿Qué aprendimos?

No todo lo visible en AWS tiene que haber sido creado explícitamente
mediante un bloque `resource`.

------------------------------------------------------------------------

## 03.8 --- Security Group

Actualmente:

``` text
Ingress → ninguno
Egress  → permitido
```

``` hcl
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

`protocol = "-1"` representa todos los protocolos.

### 🧠 ¿Qué aprendimos?

``` text
Security Group → stateful
Network ACL    → stateless
```

Podemos administrar nuestra EC2 mediante SSM sin abrir el puerto 22.

------------------------------------------------------------------------

# 04 --- Compute / EC2

## 04.1 --- Arquitectura

``` text
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

------------------------------------------------------------------------

## 04.2 --- AMI mediante Data Source

``` hcl
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

Terraform consulta AWS para localizar la AMI.

`most_recent = true` implica que el resultado puede cambiar cuando
exista una AMI más reciente que cumpla los filtros.

------------------------------------------------------------------------

## 04.3 --- `validate` vs `plan`

Durante la configuración de la AMI introdujimos un filtro que Terraform
podía validar estructuralmente, pero AWS rechazó durante el plan.

### 🧠 ¿Qué aprendimos?

``` text
terraform validate
```

comprueba la configuración que puede validarse sin realizar el
despliegue.

No garantiza que todos los valores sean aceptados posteriormente por una
API remota.

Por tanto:

``` text
validate correcto ≠ plan garantizado
plan correcto     ≠ apply garantizado
```

------------------------------------------------------------------------

## 04.4 --- EC2

``` hcl
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

``` text
VPC
 ↓
Subnet
 ↓
EC2
```

y:

``` text
IAM Role
 ↓
Instance Profile
 ↓
EC2
```

Terraform puede inferirlas mediante referencias.

------------------------------------------------------------------------

## 04.5 --- IAM Role

Creamos un Role que EC2 puede asumir mediante:

``` text
sts:AssumeRole
```

### 🧠 ¿Qué aprendimos?

``` text
Trust Policy
     ↓
¿QUIÉN puede asumir el Role?
```

``` text
Permissions Policy
     ↓
¿QUÉ puede hacer?
```

------------------------------------------------------------------------

## 04.6 --- `jsonencode()`

La Trust Policy utiliza `jsonencode()`.

``` text
Terraform value
      ↓
jsonencode()
      ↓
JSON
```

`jsondecode()` realiza la transformación inversa.

------------------------------------------------------------------------

## 04.7 --- SSM Permissions

Adjuntamos:

``` text
AmazonSSMManagedInstanceCore
```

al IAM Role.

El Role por sí solo no concede automáticamente los permisos necesarios.

------------------------------------------------------------------------

## 04.8 --- Instance Profile

Arquitectura:

``` text
EC2
 ↓
Instance Profile
 ↓
IAM Role
 ↓
Permissions
```

El Instance Profile permite asociar el Role con EC2.

------------------------------------------------------------------------

## 04.9 --- User Data

Archivo:

``` text
user-data.sh
```

Contenido:

``` bash
#!/bin/bash

set -e

apt-get update -y

echo "Terraform DevSecOps Platform" > /home/ubuntu/terraform-lab.txt
echo "EC2 configured automatically using Terraform User Data" >> /home/ubuntu/terraform-lab.txt

chown ubuntu:ubuntu /home/ubuntu/terraform-lab.txt
```

Terraform lo carga mediante:

``` hcl
user_data = file("${path.module}/user-data.sh")
```

### 🧠 ¿Qué aprendimos?

`file()` lee un archivo.

`path.module` representa el directorio del módulo actual.

User Data permite automatizar la configuración inicial de EC2.

------------------------------------------------------------------------

## 04.10 --- Troubleshooting real de SSM

Inicialmente la instancia no aparecía correctamente en Systems Manager.

Investigamos:

``` text
IAM Policy        ✅
Instance Profile  ✅
SSM Agent         ✅
Public IP         ✅
Route Table       ✅
Internet Gateway  ✅
Network ACL       ✅
Security Group    ❌
```

El Security Group no permitía egress.

SSM Agent necesita iniciar conexiones hacia servicios de AWS.

``` text
EC2
 │
 X
 │
 ▼
SSM
```

Añadimos salida permitida y Terraform mostró:

``` text
~ update in-place
```

con:

``` text
Plan: 0 to add, 1 to change, 0 to destroy.
```

### 🧠 ¿Qué aprendimos?

Terraform pudo modificar el Security Group sin reemplazarlo.

Además aprendimos a diagnosticar por capas:

``` text
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

------------------------------------------------------------------------

## 04.11 --- Systems Manager Online

Verificamos:

``` bash
aws ssm describe-instance-information
```

y obtuvimos un estado `Online`.

Para Session Manager necesitamos:

``` text
EC2
 ├── SSM Agent
 ├── IAM Role
 ├── Instance Profile
 ├── SSM Permissions
 └── Conectividad
```

------------------------------------------------------------------------

## 04.12 --- Acceso sin SSH

Utilizamos:

``` bash
aws ssm start-session \
  --target <INSTANCE_ID> \
  --profile terraform-lab \
  --region eu-west-1
```

Arquitectura:

``` text
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

No necesitamos:

``` text
❌ SSH público
❌ Puerto 22
❌ Key Pair
```

Esto reduce la superficie de exposición.

------------------------------------------------------------------------

## 04.13 --- `ssm-user`

Dentro de la sesión:

``` bash
whoami
```

devolvió:

``` text
ssm-user
```

No estábamos accediendo como `ubuntu` mediante SSH.

También distinguimos:

``` text
Permission denied
```

de:

``` text
No such file or directory
```

------------------------------------------------------------------------

## 04.14 --- Verificación del User Data

Ejecutamos:

``` bash
sudo cat /home/ubuntu/terraform-lab.txt
```

y comprobamos:

``` text
Terraform DevSecOps Platform
EC2 configured automatically using Terraform User Data
```

Flujo:

``` text
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

------------------------------------------------------------------------

## 04.15 --- Verificación del SSM Agent

Comprobamos el servicio de `amazon-ssm-agent` desde Ubuntu y verificamos
que estaba activo.

Esto confirmó tanto desde AWS como desde la propia instancia que Systems
Manager funcionaba correctamente.

------------------------------------------------------------------------

# 🔐 Arquitectura actual completa

``` text
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

------------------------------------------------------------------------

# 🔐 Git y seguridad

`.gitignore` protege archivos locales:

``` gitignore
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

``` text
*.tf
README.md
.gitignore
.terraform.lock.hcl
user-data.sh
```

No versionamos:

``` text
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
tfplan
.terraform/
```

### 🧠 ¿Qué aprendimos?

El State puede contener información sensible.

`.terraform.lock.hcl` **no es el Terraform State** ni el State Lock.
Registra las selecciones de providers y normalmente debe versionarse.

------------------------------------------------------------------------

# 🔄 Flujo de trabajo

``` text
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

------------------------------------------------------------------------

# ⚠️ Regla fundamental

Nunca aplicar cambios sin entender primero el plan.

``` text
+     create
~     update in-place
-     destroy
-/+   replacement
```

Si aparece una destrucción inesperada:

``` text
STOP
 ↓
Investigar
 ↓
Entender
 ↓
Corregir si procede
 ↓
Aplicar únicamente cuando sea correcto
```

------------------------------------------------------------------------

# 🧪 Comandos Terraform utilizados

``` bash
terraform init
terraform init -migrate-state

terraform fmt
terraform validate

terraform plan
terraform plan -out=tfplan
terraform apply
terraform apply tfplan

terraform output
terraform output -raw ec2_instance_id

terraform show

terraform state list
terraform state show aws_instance.devsecops
terraform state show aws_vpc.main
```

Conceptos estudiados además:

``` bash
terraform state mv
terraform state rm
terraform import
terraform force-unlock
```

------------------------------------------------------------------------

# 🧪 AWS CLI utilizado

Hemos utilizado AWS CLI para verificar:

``` text
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

Entre otros:

``` bash
aws ssm describe-instance-information
aws ssm start-session
```

y para Remote State:

``` bash
aws s3 ls s3://terraform-aws-devsecops-dt97-state/ --recursive \
  --profile terraform-lab
```

``` bash
aws s3api list-object-versions \
  --bucket terraform-aws-devsecops-dt97-state \
  --prefix dev/terraform.tfstate \
  --profile terraform-lab
```

------------------------------------------------------------------------

# 🧠 Conceptos aprendidos

## Terraform

-   Infrastructure as Code.
-   Configuración declarativa.
-   Providers.
-   Backends.
-   Resources.
-   Data Sources.
-   `resource` vs `data`.
-   Terraform State.
-   Local State.
-   Remote State.
-   S3 Backend.
-   State Migration.
-   State Locking.
-   State Versioning.
-   State Encryption.
-   Dependency Graph.
-   Implicit dependencies.
-   Resource references.
-   Variables.
-   `terraform.tfvars`.
-   Locals.
-   Outputs.
-   `file()`.
-   `path.module`.
-   `jsonencode()`.
-   `jsondecode()`.
-   `(known after apply)`.
-   `terraform fmt`.
-   `terraform validate`.
-   `terraform plan`.
-   Saved Plans.
-   `terraform apply`.
-   Update in-place.
-   Resource replacement.
-   Plan symbols.
-   Drift.
-   Import.
-   State manipulation.
-   Idempotencia.
-   Provider/API validation.
-   `.terraform.lock.hcl`.

## AWS Networking

-   VPC.
-   CIDR.
-   Public / Private Subnets.
-   Availability Zones.
-   Internet Gateway.
-   Route Tables.
-   Routes.
-   Default Route.
-   Local Route.
-   Associations.
-   Main Route Table.
-   Security Groups.
-   Network ACL.
-   Stateful vs Stateless.
-   Public IPv4.

## AWS Compute

-   EC2.
-   AMI.
-   Ubuntu Server.
-   Instance Type.
-   User Data.
-   cloud-init.
-   Public / Private IP.

## AWS IAM

-   IAM Role.
-   Trust Policy.
-   Permissions Policy.
-   `sts:AssumeRole`.
-   Managed Policies.
-   Policy Attachment.
-   Instance Profile.

## AWS Systems Manager

-   SSM Agent.
-   Session Manager.
-   Managed Instance.
-   `ssm-user`.
-   Administración sin SSH.
-   Diagnóstico de conectividad.

## Amazon S3

-   Bucket.
-   Public Access Block.
-   Server-Side Encryption.
-   AES256 / SSE-S3.
-   Versioning.
-   Remote Terraform State.
-   Native S3 State Locking.
-   `.tflock`.

## DevOps / DevSecOps

-   Git.
-   GitHub.
-   `.gitignore`.
-   Infrastructure versioning.
-   Incremental changes.
-   Validation before deployment.
-   AWS CLI verification.
-   Troubleshooting por capas.
-   Documentación.
-   Reducción de superficie de exposición.
-   Automatización de configuración.

------------------------------------------------------------------------

# 📊 Estado actual

``` text
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
│   ├── Verificación Remote State                ✅
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
│   ├── Troubleshooting SSM                      ✅
│   └── terraform plan → No changes              ✅
│
└── 05 — Terraform intermedio / avanzado         ⏳
```

------------------------------------------------------------------------

# 🎓 Puntos importantes para Terraform Associate

Conceptos especialmente relevantes practicados en este proyecto:

``` text
Configuration ≠ State ≠ Infrastructure
```

``` text
Provider ≠ Backend
```

``` text
resource ≠ data
```

``` text
.terraform.lock.hcl ≠ State Lock
```

``` text
S3 Versioning ≠ State Locking
```

``` text
sensitive = true ≠ State cifrado
```

``` text
state rm ≠ destroy
```

``` text
terraform import ≠ crear infraestructura
```

``` text
validate correcto ≠ API remota garantizada
```

``` text
known after apply ≠ error
```

Y la idea central:

``` text
CONFIGURATION
¿Qué quiero?
      │
      ▼
STATE
¿Qué gestiona Terraform y con qué objeto real?
      │
      ▼
PROVIDER
¿Cómo interactúa con AWS?
      │
      ▼
AWS
¿Qué existe realmente?
```

El backend responde a otra pregunta:

``` text
BACKEND
¿Dónde y cómo almacenamos el State?
```

------------------------------------------------------------------------

# 🚀 Próximos pasos

El siguiente bloque profundizará en Terraform intermedio y avanzado:

-   `count`
-   `for_each`
-   expresiones `for`
-   condicionales
-   funciones
-   bloques `dynamic`
-   `depends_on`
-   `lifecycle`
-   importación
-   bloques `moved`
-   refactoring seguro

Posteriormente el proyecto evolucionará hacia automatización y
DevSecOps:

``` text
Git
 │
 ▼
CI/CD
 │
 ├── Format
 ├── Validate
 ├── Security
 ├── Plan
 ├── Approval
 └── Apply
       │
       ▼
      AWS

Remote State ─────► S3
```

El objetivo final es combinar:

**Terraform + AWS + Infrastructure as Code + Automation + CI/CD +
DevSecOps**

manteniendo siempre una regla:

> **No añadir tecnología por añadirla. Cada componente debe resolver una
> necesidad concreta y debemos entender por qué existe.**
