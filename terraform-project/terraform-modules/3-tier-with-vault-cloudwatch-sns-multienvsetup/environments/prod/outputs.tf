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
output "debug_rds_password_TEMP" {
  value     = data.vault_kv_secret_v2.rds_password.data["password"]
  sensitive = true
}
output "sns_topic_arn" {
  value = module.monitoring.sns_topic_arn
}
