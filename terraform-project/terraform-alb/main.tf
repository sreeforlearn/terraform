provider "aws" {
  region = "ap-south-1"
}
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["prod-vpc"]   # నీ VPC కి ఇచ్చిన Name tag
  }
}
data "aws_instance" "public_web" {
  filter {
    name   = "tag:Name"
    values = ["Final-public-ec2"]
  }
}

# Public subnet
data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = ["prod-public-1-subnet"]   # Public subnet కి ఇచ్చిన Name tag
  }
  vpc_id = data.aws_vpc.selected.id
}
data "aws_subnet" "public2" {
  filter {
    name   = "tag:Name"
    values = ["prod-public-2-subnet"]   # Public subnet కి ఇచ్చిన Name tag
  }
  vpc_id = data.aws_vpc.selected.id
}


# Private subnet
data "aws_subnet" "private" {
  filter {
    name   = "tag:Name"
    values = ["prod-private-1-subnet"]  # Private subnet కి ఇచ్చిన Name tag
  }
  vpc_id = data.aws_vpc.selected.id
}


# security Group  for ALB
resource "aws_security_group" "alb_public_sg" {
  name = "alb-public-sg"
  vpc_id = data.aws_vpc.selected.id
  ingress {
    description = "HTTP from internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
  }
}

# Target Group
resource "aws_lb_target_group" "web_tg" {
  name = "web-server-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.selected.id
  health_check {
    path = "/"
    interval = 30
    timeout = 5
    healthy_threshold = 2
   unhealthy_threshold = 2
  }
}

# Appliaction load Balancer

resource "aws_lb" "web_alb" {
  name = "production-web-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_public_sg.id]
  subnets = [data.aws_subnet.public.id, data.aws_subnet.public2.id]
  tags = {
    Name = "production alb"
  }
}

# listener port

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port = 80
  protocol = "HTTP"
  
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }

}

# target group attachment

resource "aws_lb_target_group_attachment" "public_ec2_attach"{
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id =  data.aws_instance.public_web.id
  port = 80
}

output "alb_dns_name" {


  description = " Need to paste on Browser"
  value = aws_lb.web_alb.dns_name

}
