provider "aws" {
  region = "ap-south-1"
}
variable "buckets" {
  type = map(string)
  default = {
    "logs"   = "my-app-logs-bucket"
    "data"   = "my-app-data-bucket"
    "backup" = "my-app-backup-bucket"
  }
}

resource "aws_s3_bucket" "example" {
  for_each = var.buckets
  bucket   = "each.value"
  tags = {
    purpose = each.key
  }

}
