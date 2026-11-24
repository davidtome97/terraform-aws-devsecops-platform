module "network" {
  source = "./modules/network"

  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone   = var.availability_zone
  project_name        = var.project_name
  name_prefix         = local.name_prefix
}

module "security" {
  source = "./modules/security"

  vpc_id       = module.network.vpc_id
  project_name = var.project_name
  name_prefix  = local.name_prefix
}

module "compute" {
  source = "./modules/compute"

  instance_type     = var.instance_type
  subnet_id         = module.network.public_subnet_id
  security_group_id = module.security.security_group_id
  project_name      = var.project_name
  name_prefix       = local.name_prefix

}