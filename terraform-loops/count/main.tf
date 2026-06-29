provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "logs" {
  count  = 3
  bucket = "my-app-logs-${count.index}"
}

variable "enable_backup_bucket" {
  type    = bool
  default = false
}

resource "aws_s3_bucket" "backup" {
  count  = var.enable_backup_bucket ? 1 : 0
  bucket = "my-app-backup-bucket"

}
