module "networking" {
  source          = "./modules/networking"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  allowed_admin_ip = var.allowed_admin_ip
}

module "compute" {
  source             = "./modules/compute"
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnets
  private_subnet_ids = module.networking.private_subnets
  ecs_sg_id          = module.networking.ecs_sg_id
  alb_sg_id          = module.networking.alb_sg_id
  monitoring_sg_id   = module.networking.monitoring_sg_id
}


module "database" {
  source             = "./modules/database"
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnets
  ecs_sg_id          = module.networking.ecs_sg_id
  db_username        = var.db_username
}

module "wordpress" {
  source             = "./modules/wordpress"
  cluster_id         = module.compute.cluster_id
  execution_role_arn = module.compute.ecs_task_execution_role_arn
  target_group_arn   = module.compute.target_group_arn
  private_subnet_ids = module.networking.private_subnets
  ecs_sg_id          = module.networking.ecs_sg_id
  db_host_arn        = module.database.db_host_arn
  db_user_arn        = module.database.db_user_arn
  db_password_arn    = module.database.db_password_arn
  db_name            = "wordpressdb"
}

module "monitoring" {
  source                   = "./modules/monitoring"
  alert_email              = var.alert_email
  ecs_cluster_id           = module.compute.cluster_id
  ecs_execution_role_arn   = module.compute.ecs_task_execution_role_arn
  prometheus_task_role_arn = module.compute.prometheus_task_role_arn
  private_subnet_ids       = module.networking.private_subnets
  monitoring_sg_id         = module.networking.monitoring_sg_id
  monitoring_efs_id        = module.compute.monitoring_efs_id
}