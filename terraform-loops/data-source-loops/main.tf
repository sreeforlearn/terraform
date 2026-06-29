provider "aws" { region = "ap-south-1" }

# ==========================================
# STEP 1: DATA SOURCE (Querying AWS)
# ==========================================
# AWS lo default VPC ni query chestundi (Read-only, em create cheyyatledu)
data "aws_vpc" "default" {
  default = true
}

# Default VPC lo unna 'private' subnets ni filter chestundi (Returns a LIST of IDs)
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*Private*"] # Nee account lo name lo "Private" unna subnets teesukostundi
  }
}

# ==========================================
# STEP 2: LOCALS (The Real-World Magic)
# ==========================================
# for_each ki MAP kavali. But data.aws_subnets.private.ids oka LIST istundi.
# So, list ni map ga convert chestunnam (Logic practice ki super!)
locals {
  # Converting ["subnet-111", "subnet-222"] into { "subnet-111" = "subnet-111", "subnet-222" = "subnet-222" }
  subnet_map = { for subnet_id in data.aws_subnets.private.ids : subnet_id => subnet_id }
}

# ==========================================
# STEP 3: FOR_EACH (Dynamic Creation)
# ==========================================
# Query chesina subnet count ki equal ga Security groups create avuthayi!
resource "aws_security_group" "app_sg" {
  for_each = local.subnet_map

  name        = "app-sg-for-${each.key}"
  description = "Security group dynamically created for subnet ${each.key}"
  vpc_id      = data.aws_vpc.default.id

  # Basic rule just to make it valid
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    SubnetID  = each.key
    CreatedBy = "Terraform-Logic"
  }
}

# ==========================================
# STEP 4: OUTPUTS (To see the magic)
# ==========================================
output "queried_subnet_count" {
  value       = length(data.aws_subnets.private.ids)
  description = "Manam query chesina subnets count"
}

output "created_sg_names" {
  value       = [for sg in aws_security_group.app_sg : sg.name]
  description = "Dynamically create ayyina SG names list"
}
