variable "aws_region" {
  description = "AWS region used to configure the provider"
  type        = string
  default     = "eu-west-1"
}

variable "aws_profile" {
  description = "Local AWS CLI profile used to bootstrap GitHub OIDC"
  type        = string
  default     = "terraform-lab"
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "davidtome97"
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
  default     = "terraform-aws-devsecops-platform"
}

variable "terraform_state_bucket" {
  description = "S3 bucket containing the Terraform remote state"
  type        = string
  default     = "terraform-aws-devsecops-dt97-state"
}

variable "terraform_state_key" {
  description = "S3 object key containing the Terraform state"
  type        = string
  default     = "dev/terraform.tfstate"
}

variable "terraform_state_kms_key_arn" {
  description = "KMS key ARN used to encrypt the Terraform remote state"
  type        = string

  default = "arn:aws:kms:eu-west-1:490145258703:key/0dbb031d-fa1b-4759-a946-dd99e247b098"
}