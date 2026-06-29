resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

locals {
  subnet_specs = [
    { name = "public-1", az_index = 0, cidr_num = 0, type = "public" },
    { name = "public-2", az_index = 1, cidr_num = 1, type = "public" },
    { name = "private-1", az_index = 0, cidr_num = 2, type = "private" },
    { name = "private-2", az_index = 1, cidr_num = 3, type = "private" }
  ]
  subnet_map = { for s in local.subnet_specs : s.name => s }
}

resource "aws_subnet" "this" {
  for_each = local.subnet_map

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, each.value.cidr_num)
  availability_zone       = var.availability_zones[each.value.az_index]
  map_public_ip_on_launch = each.value.type == "public"

  tags = {
    Name = "${var.environment}-${each.value.name}-subnet"
    Type = each.value.type
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.environment}-igw" }
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.this["public-1"].id
  depends_on    = [aws_internet_gateway.igw]

  tags = { Name = "${var.environment}-nat" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.environment}-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat[0].id
    }
  }
  tags = { Name = "${var.environment}-private-rt" }
}

resource "aws_route_table_association" "public" {
  for_each       = { for k, v in local.subnet_map : k => k if v.type == "public" }
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = { for k, v in local.subnet_map : k => k if v.type == "private" }
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private.id
}
