provider "aws" {
  region = "ap-south-1"
}

# VPC
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["prod-vpc"]
  }
}

# Public subnets (2 AZs needed for ALB)
data "aws_subnet" "public1" {
  filter {
    name   = "tag:Name"
    values = ["prod-public-1-subnet"]
  }
  vpc_id = data.aws_vpc.selected.id
}

data "aws_subnet" "public2" {
  filter {
    name   = "tag:Name"
    values = ["prod-public-2-subnet"]
  }
  vpc_id = data.aws_vpc.selected.id
}

# AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# SG for instances - only allow traffic from ALB
resource "aws_security_group" "public_sg" {
  name   = "asg-public-sg"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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
}

# SG for ALB
resource "aws_security_group" "alb_sg" {
  name   = "asg-alb-sg"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template
resource "aws_launch_template" "web_template" {
  name          = "web-server-template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.nano"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.public_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Hello from Server: $(hostname -f)</h1>" > /usr/share/nginx/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Asg-web-server"
    }
  }
}

# Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "web-server-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ALB
resource "aws_lb" "web_alb" {
  name               = "production-web-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [data.aws_subnet.public1.id, data.aws_subnet.public2.id]
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name = "production-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  name                = "web-asg-prod"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = [data.aws_subnet.public1.id, data.aws_subnet.public2.id]

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]
  health_check_type = "ELB"

  tag {
    key                 = "Environment"
    value               = "prod"
    propagate_at_launch = true
  }
  tag {
    key                 = "Name"
    value               = "Asg-web-server"
    propagate_at_launch = true
  }
}

output "alb_dns_name" {
  description = "ALB DNS - browser lo type cheyi"
  value       = aws_lb.web_alb.dns_name
}
