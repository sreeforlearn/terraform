terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-9876547969" # Create this bucket manually first or use previous script
    key            = "ec2-project/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks" # Locking kosam
  }
}
