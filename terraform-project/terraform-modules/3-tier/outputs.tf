output "alb_dns_name" {
  description = "Browser lo type cheyyali"
  value       = module.alb.alb_dns_name
}

output "log_bucket_name" {
  value = module.s3_logging.bucket_name
}

output "rds_endpoint" {
  description = "RDS endpoint (null if create_rds = false)"
  value       = var.create_rds ? module.rds[0].rds_endpoint : null
}
