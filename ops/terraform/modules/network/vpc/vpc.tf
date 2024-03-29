#--------------------------------------------------------------
# This module creates all resources necessary for a VPC
#--------------------------------------------------------------

variable "name" {
  default = "vpc"
}

variable "cidr" {
}

variable "environment" {
}

resource "aws_vpc" "vpc" {
  cidr_block                       = var.cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name        = var.name
    Environment = var.environment
  }
  lifecycle {
    create_before_destroy = true
  }
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "vpc_ipv6_cidr" {
  value = aws_vpc.vpc.ipv6_cidr_block
}

