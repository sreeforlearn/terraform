variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "alb_sg_id" {
  type = string
}
variable "target_group_arn" {
  type = string
}

variable "instance_type" {
  type = string
}
variable "min_size" {
  type = number
}
variable "max_size" {
  type = number
}
variable "desired_capacity" {
  type = number
}

variable "iam_instance_profile_name" {
  type = string
}
variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "cpu_target_value" {
  type    = number
  default = 50
}

variable "request_count_target_value" {
  type    = number
  default = 1000
}

