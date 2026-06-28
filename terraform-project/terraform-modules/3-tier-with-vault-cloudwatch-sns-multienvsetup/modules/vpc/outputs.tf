output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_subnet_ids" {
  value = [aws_subnet.this["public-1"].id, aws_subnet.this["public-2"].id]
}
output "private_subnet_ids" {
  value = [aws_subnet.this["private-1"].id, aws_subnet.this["private-2"].id]
}
