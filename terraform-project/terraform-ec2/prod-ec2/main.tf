# provider
provider "aws" {
  region = "ap-south-1"
}
# variables
#variable "vpc_id" { type = string }
#variable "public_subnet_id" { type = string }
#variable "private_subnet_id" { type = string }
# VPC ని dynamic గా తీసుకోవడం
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["prod-vpc"]   # నీ VPC కి ఇచ్చిన Name tag
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

# Private subnet
data "aws_subnet" "private" {
  filter {
    name   = "tag:Name"
    values = ["prod-private-1-subnet"]  # Private subnet కి ఇచ్చిన Name tag
  }
  vpc_id = data.aws_vpc.selected.id
}



#Dynamic ami
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter{
    name = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}
# Security Groups - public
resource "aws_security_group" "public_sg" {
  name = "public-ec2-sg"
  vpc_id = data.aws_vpc.selected.id
  ingress {
    description = "HTTP from Internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
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
# Security Group - private
resource "aws_security_group" "private_sg" {
  name = "private-ec2-sg"
  vpc_id = data.aws_vpc.selected.id
  ingress {
    description = "HTTP only from public SG"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Key pair generate చేసి AWS లో store చేయడం
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "example" {
  key_name   = "terraform-key"
  public_key = tls_private_key.example.public_key_openssh
}

# PEM file local గా save చేయడం
resource "local_file" "private_key_pem" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/terraform-key.pem"
}




#EC2 Instances
resource "aws_instance" "public_web" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t2.nano"
  subnet_id = data.aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  key_name               = aws_key_pair.example.key_name 
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo '<h1>Hello from Public Server</h1>' > /var/www/html/index.html
              EOF
  tags = {
    Name = "Final-public-ec2"
  }
}

resource "aws_instance" "private_web" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t2.nano"
  subnet_id = data.aws_subnet.private.id
  vpc_security_group_ids = [ aws_security_group.private_sg.id]
  associate_public_ip_address = false
  key_name               = aws_key_pair.example.key_name 
  user_data = <<-EOF
              #!/bin/bash
               dnf update -y
               dnf install -y nginx
               systemctl start nginx
               systemctl enable nginx
               echo '<h1>Hello from Private Server</h1>' > /var/www/html/index.html
               EOF
  tags = {
    Name = "Final-Private-Ec2"
  }
}
#Output
output "public_ip_to_test_in_browser" {
  description = "Browser lo type cheyyali "
  value = aws_instance.public_web.public_ip
}

output "private_ip_for_internal_testing" {
  description = "Public ec2 loki velli curl cheyali"
  value = aws_instance.private_web.private_ip

}
output "public_web_id" {
  value = aws_instance.public_web.id
}

output "private_web_id" {
  value = aws_instance.private_web.id
}

