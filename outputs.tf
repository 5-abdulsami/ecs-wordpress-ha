output "database_endpoint" {
  value = module.database.db_endpoint
}

output "wordpress_url" {
  value = module.compute.alb_dns_name
}
