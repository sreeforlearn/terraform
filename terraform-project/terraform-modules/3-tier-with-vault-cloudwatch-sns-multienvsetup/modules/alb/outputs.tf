output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "target_group_arn" {
  value = aws_lb_target_group.web_tg.arn
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}

output "alb_arn" {
  value = aws_lb.web_alb.arn
}

output "alb_arn_suffix" {
  value = aws_lb.web_alb.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.web_tg.arn_suffix
}

