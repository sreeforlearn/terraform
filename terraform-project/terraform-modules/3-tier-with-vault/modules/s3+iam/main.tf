###################################
# S3 bucket --public access block -- s3 bucket versioning +++ iam policy --iam role --iam role policy attachment
###################################
resource "aws_s3_bucket" "nginx_logs" {
  bucket = var.bucket_name
}
############################
# S3 public block access
############################
resource "aws_s3_bucket_public_access_block" "nginx_logs" {
  bucket                  = aws_s3_bucket.nginx_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
##########################
# S3 Bucket Versioning
##########################
resource "aws_s3_bucket_versioning" "nginx_logs" {
  bucket = aws_s3_bucket.nginx_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}
#########################
# Iam Policy
#########################
resource "aws_iam_policy" "s3_write_policy" {
  name        = "${var.environment}-NginxLogsWritePolicy"
  description = "Allow ec2 to write logs only to our specific bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.nginx_logs.arn,
          "${aws_s3_bucket.nginx_logs.arn}/*"
        ]
      }
    ]
  })
}

########################
# Iam ROLE
#######################
resource "aws_iam_role" "ec2_logging_role" {
  name = "${var.environment}-EC2-Nginx-Logging-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
#######################
# Role Attachment
########################
resource "aws_iam_role_policy_attachment" "logging_attach" {
  role       = aws_iam_role.ec2_logging_role.name
  policy_arn = aws_iam_policy.s3_write_policy.arn
}
#######################
# IAM instance
######################
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-EC2-logging-profile"
  role = aws_iam_role.ec2_logging_role.name
}

























