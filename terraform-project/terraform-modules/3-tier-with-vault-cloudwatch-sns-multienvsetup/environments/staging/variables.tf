variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "instance_type" {
  type    = string
  default = "t2.nano"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "create_rds" {
  type    = bool
  default = true
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "admin"
}


variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "log_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for nginx logs"
}
variable "notification_email" {
  type        = string
  description = "Email address to receive SNS alerts"
}

variable "cpu_target_value" {
  type    = number
  default = 50
}

variable "request_count_target_value" {
  type    = number
  default = 1000
}
