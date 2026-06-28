# ENV
variable "environment" {
  type = string
}
# CIDR
variable "vpc_cidr" {
  type = string
}
# AZ
variable "availability_zones" {
  type = list(string)
}
# Enable Nat
variable "enable_nat_gateway" {
  type = bool
  default = false
}

