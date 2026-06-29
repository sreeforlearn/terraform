provider "aws" {
  region = "ap-south-1"
}

# ==========================================
# Data sources needed in this file
# ==========================================
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["prod-vpc"]
  }
}

data "aws_subnet" "private1" {
  filter {
    name   = "tag:Name"
    values = ["prod-private-1-subnet"]
  }
  vpc_id = data.aws_vpc.selected.id
}

data "aws_subnet" "private2" {
  filter {
    name   = "tag:Name"
    values = ["prod-private-2-subnet"]
  }
  vpc_id = data.aws_vpc.selected.id
}

data "aws_security_group" "asg_web_sg" {
  filter {
    name   = "group-name"
    values = ["public-ec2-sg"]
  }
  vpc_id = data.aws_vpc.selected.id
}
variable "db_password" {
  description = "RDS master password - set via terraform.tfvars or TF_VAR_db_password"
  type        = string
  sensitive   = true
}

# ==========================================
# 12. DB SUBNET GROUP (RDS Mapping)
# ==========================================
resource "aws_db_subnet_group" "main" {
  name       = "prod-db-subnet-group"
  subnet_ids = [data.aws_subnet.private1.id, data.aws_subnet.private2.id]
  tags = {
    Name = "Prod-DB-Subnet-Group"
  }
}

# ==========================================
# 13. RDS SECURITY GROUP (Strict Access)
# ==========================================
resource "aws_security_group" "rds_sg" {
  name   = "rds-mysql-sg"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    description     = "MySQL access only from Web EC2s (ASG)"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.aws_security_group.asg_web_sg.id]
  }
  egress {
    description = "Allow all outbound (default)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# 14. RDS MYSQL INSTANCE
# ==========================================
resource "aws_db_instance" "main" {
  identifier        = "prod-mysql-db"
  allocated_storage = 20
  db_name           = "appdb"

  username = "admin"
  password = var.db_password

  engine         = "mysql"
  instance_class = "db.t3.micro"


  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az = false

  skip_final_snapshot = true # <<< PROD LO IDHI FALSE CHEYYAKU! Data pothundi!
  publicly_accessible = false

  tags = {
    Name = "Prod-MySQL-DB"
  }
}

output "rds_endpoint" {
  description = "EC2 loki velli idhi use cheyyali DB connect cheyyadaniki"
  value       = aws_db_instance.main.endpoint
}
