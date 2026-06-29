data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name   = "${var.environment}-asg-ec2-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-asg-ec2-sg" }
}

resource "aws_launch_template" "web_template" {
  name          = "${var.environment}-web-server-template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl enable --now nginx

              cat <<EOT > /usr/share/nginx/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <title>Dev Environment</title>
                <style>
                  body {
                    background-color: #f0f8ff;
                    font-family: Arial, sans-serif;
                    text-align: center;
                    margin-top: 100px;
                  }
                  h1 {
                    color: #2e8b57;
                    font-size: 48px;
                  }
                  p {
                    color: #555;
                    font-size: 20px;
                  }
                  .env-banner {
                    background-color: #ffcc00;
                    padding: 15px;
                    border-radius: 8px;
                    display: inline-block;
                    margin-top: 20px;
                    font-weight: bold;
                    color: #000;
                  }
                </style>
              </head>
              <body>
                <h1>Hello from Server: $(hostname -f)</h1>
                <p>Welcome to the <strong>Development Environment</strong></p>
                <div class="env-banner">⚡ DEV ENVIRONMENT ⚡</div>
              </body>
              </html>
              EOT
              EOF
  )


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-asg-web-server"
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                      = "${var.environment}-web-asg"
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  vpc_zone_identifier       = var.public_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  target_group_arns = [var.target_group_arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-asg-web-server"
    propagate_at_launch = true
  }
}
###############################
# ASG Policy
################################
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.environment}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}

resource "aws_autoscaling_policy" "request_count_target_tracking" {
  name                   = "${var.environment}-request-count-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${var.alb_arn_suffix}/${var.target_group_arn_suffix}"
    }
    target_value = var.request_count_target_value
  }
}
