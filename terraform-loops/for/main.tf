provider "aws" {
  region = "ap-south-1"
}

locals {
  my_buckets = {
    "bucket_a" = "arn:aws:s3:::bucket-a"
    "bucket_b" = "arn:aws:s3:::bucket-b"
    "bucket_c" = "arn:aws:s3:::bucket-c"
  }
}

output "bucket_names_list" {
  value = [for name, arn in local.my_buckets : name]
}

output "upper_arn_map" {
  value = { for name, arn in local.my_buckets : upper(name) => arn }
}
output "filtered_buckets" {
  value = {
    for name, arn in local.my_buckets :
    name => arn if length(regexall("a", name)) > 0
  }
}

