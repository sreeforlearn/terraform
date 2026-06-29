provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "web_sg" {
  name        = "dynamic-web-sg"
  description = "SG created using dynamic block"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

    }
  }

}
