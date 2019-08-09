variable "vpc_id" {
}

variable "public_subnet_ids" {
}

variable "region" {
}

variable "route_table" {
  type = list(string)
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table
}

output "s3_prefix_list_id" {
  value = aws_vpc_endpoint.s3.prefix_list_id
}

