provider "aws" {
  region = "ap-south-1"
}

#varibales.tf

variable "s3_bucket_name" {
  type = string
  description = "S3 bucket Name"
  default = "iamdefault-named-bucket"
}

resource "aws_s3_bucket" "example" {
  bucket = var.s3_bucket_name
}

output "bucket_arn" {
  value = aws_s3_bucket.example.arn
  description = "It give arn of s3"
}
