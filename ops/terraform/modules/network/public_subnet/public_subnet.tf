#--------------------------------------------------------------
# This module creates all resources necessary for a public
# subnet
#--------------------------------------------------------------

variable "name" {
  default = "public"
}

variable "vpc_id" {
}

variable "cidrs" {
}

variable "ipv6_cidr_block" {
}

variable "azs" {
}

variable "environment" {
}

resource "aws_internet_gateway" "public" {
  vpc_id = var.vpc_id

  tags = {
    Name        = var.name
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  vpc_id            = var.vpc_id
  cidr_block        = element(split(",", var.cidrs), count.index)
  ipv6_cidr_block   = cidrsubnet(var.ipv6_cidr_block, 8, count.index)
  availability_zone = element(split(",", var.azs), count.index)
  count             = length(split(",", var.cidrs))

  tags = {
    Name        = "${var.name}.${element(split(",", var.azs), count.index)}"
    Environment = var.environment
  }
  lifecycle {
    create_before_destroy = true
  }

  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.public.id
  }

  tags = {
    Name        = "${var.name}.${element(split(",", var.azs), 0)}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(split(",", var.cidrs))
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

output "subnet_ids" {
  value = join(",", aws_subnet.public.*.id)
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

