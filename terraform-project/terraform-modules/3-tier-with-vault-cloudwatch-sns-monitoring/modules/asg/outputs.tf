output "ec2_sg_id" {
  value = aws_security_group.ec2_sg.id
}
output "asg_name" {
  value = aws_autoscaling_group.web_asg.name
}
output "launch_template_id" {
  value = aws_launch_template.web_template.id
}

