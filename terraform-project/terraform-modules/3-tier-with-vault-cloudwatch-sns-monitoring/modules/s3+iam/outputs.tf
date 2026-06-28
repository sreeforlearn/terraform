output "bucket_name" {
  value = aws_s3_bucket.nginx_logs.bucket
}
output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}
