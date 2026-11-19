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