variable "vpc_cidr" {
  description = "Main VPC cidr block"
  type = string
  default = "10.0.0.0/16"
}

variable "environment" {
  description = "Env name for tagging"
  type = string
  default = "prod"
}

variable "availability_zones" {
  description = "List of AZs"
  type = list(string)
  default = ["ap-south-1a","ap-south-1b","ap-south-1c"]
}

variable "enable_nat_gateway" {
  description = "false chesthe bill ravadu, true chesthey NAT create ayutundhi"
  type = bool
  default = false
}
