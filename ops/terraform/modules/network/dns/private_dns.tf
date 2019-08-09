#--------------------------------------------------------------
# This module creates all resources necessary for a dns
#--------------------------------------------------------------

variable "vpc_id" {
}

variable "domain" {
}

variable "environment" {
}

resource "aws_route53_zone" "internal" {
  name = "${var.environment}.internal.${var.domain}"

  vpc {
    vpc_id = var.vpc_id
  }
}

output "internal_dns_zone_id" {
  value = aws_route53_zone.internal.zone_id
}

