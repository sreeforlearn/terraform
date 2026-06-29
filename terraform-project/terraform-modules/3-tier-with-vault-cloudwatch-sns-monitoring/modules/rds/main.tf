#################################
# db subnet group --db security group -- db instance
###################################
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "${var.environment}-db-subnet-group" }
}
#####################################
# DB security Group
#####################################

resource "aws_security_group" "rds_sg" {
  name   = "${var.environment}-rds-mysql-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "MySQL access only from Web EC2s"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ec2_sg_id]
  }
  egress {
    description = "Allow all outbound rule"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = { Name = "${var.environment}-rds-sg" }
}
#######################################
# DB Instance
#######################################
resource "aws_db_instance" "main" {
  identifier             = "${var.environment}-mysql-db"
  allocated_storage      = var.allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  engine                 = "mysql"
  instance_class         = var.instance_class
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az               = false
  skip_final_snapshot    = true
  publicly_accessible    = false
  tags                   = { Name = "${var.environment}-mysql-db" }

}
