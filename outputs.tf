output "alb_dns_name" {
  value = module.web.alb_dns_name
}

output "ec2_public_ip" {
  value = module.web.ec2_public_ip
}

output "rds_endpoint" {
  value = module.db.rds_endpoint
}
