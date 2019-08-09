#-------------------------------
# DNS
#-------------------------------

variable "zone_id" {
}

variable "domain_name" {
}

variable "aws_lb_dns_name" {
}

variable "aws_lb_zone_id" {
}

resource "aws_route53_record" "domain" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.aws_lb_dns_name
    zone_id                = var.aws_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "domain_ipv6" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = var.aws_lb_dns_name
    zone_id                = var.aws_lb_zone_id
    evaluate_target_health = true
  }
}

