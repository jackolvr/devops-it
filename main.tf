module "network" {
  source        = "./modules/network"
  project       = var.project
  vpc_cidr      = "10.10.0.0/16"
  public_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_cidrs = ["10.10.101.0/24", "10.10.102.0/24"]
  azs           = ["sa-east-1a", "sa-east-1b"]
}

module "web" {
  source            = "./modules/web"
  project           = var.project
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  ami_id            = local.chosen_ami
  instance_type     = var.instance_type
  user_data         = file("${path.module}/user_data/al2023_nginx.sh")
  ssh_key_name      = var.ssh_key_name
  my_ip_cidr        = var.my_ip_cidr
}

module "db" {
  source              = "./modules/db"
  project             = var.project
  vpc_id              = module.network.vpc_id
  db_subnet_ids       = module.network.private_subnet_ids
  db_engine           = var.db_engine
  db_engine_version   = var.db_engine_version
  db_instance_class   = var.db_instance_class
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  app_cidr_allow_list = module.network.app_cidrs_for_db
}