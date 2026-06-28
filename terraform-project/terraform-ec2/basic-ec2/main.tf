provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "my-ec2-sg" {
  name = "allow_web"
  description = "allow web inbound traffic"
  
  ingress {
    from_port = "80"
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0"]
  }
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks =  [ "0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami = "ami-0bc7aabcf58d1e02a"
  instance_type = "t2.nano"
  vpc_security_group_ids = [aws_security_group.my-ec2-sg.id]
  tags = {
     Name = "My-firstterraform-server"
  }
  
}

output "public_ip" {
  description = "Its Show Public IP"
  value = aws_instance.web.public_ip


}
