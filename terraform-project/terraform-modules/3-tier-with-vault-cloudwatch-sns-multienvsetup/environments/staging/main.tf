terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}
#############################
# PROVIDER
#############################
provider "aws" {
  region = var.aws_region
}

provider "vault" {
  skip_child_token = true 
}

data "vault_kv_secret_v2" "rds_password" {
  mount = "secret"
  name  = "staging/rds"
}

########################
# Backend state
###########################
terraform {
  backend "s3" {
    bucket         = "state-lock-s3-for-tester-by-sree" # same name as above
    key            = "envs/staging/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
module "vpc" {
  source = "../../modules/vpc"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_nat_gateway = var.enable_nat_gateway
}

module "s3_logging" {
  source = "../../modules/s3+iam"

  bucket_name = var.log_bucket_name
  environment = var.environment
}

module "alb" {
  source = "../../modules/alb"

  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "asg" {
  source = "../../modules/asg"

  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_sg_id                  = module.alb.alb_sg_id
  target_group_arn           = module.alb.target_group_arn
  instance_type              = var.instance_type
  min_size                   = var.asg_min_size
  max_size                   = var.asg_max_size
  desired_capacity           = var.asg_desired_capacity
  iam_instance_profile_name  = module.s3_logging.instance_profile_name
  alb_arn_suffix             = module.alb.alb_arn_suffix
  target_group_arn_suffix    = module.alb.target_group_arn_suffix
  cpu_target_value           = var.cpu_target_value
  request_count_target_value = var.request_count_target_value
}
module "rds" {
  count  = var.create_rds ? 1 : 0
  source = "../../modules/rds"

  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ec2_sg_id          = module.asg.ec2_sg_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = data.vault_kv_secret_v2.rds_password.data["password"]
  instance_class     = var.db_instance_class
  allocated_storage  = var.db_allocated_storage
}
module "monitoring" {
  source = "../../modules/monitoring"

  environment             = var.environment
  notification_email      = var.notification_email
  asg_name                = module.asg.asg_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
}
