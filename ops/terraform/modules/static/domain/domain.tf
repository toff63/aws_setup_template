variable "domain_name" {
}

variable "target_domain_name" {
}

variable "target_bucket_zone_id" {
}

variable "zone_id" {
}

resource "aws_route53_record" "domain" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.target_domain_name
    zone_id                = var.target_bucket_zone_id
    evaluate_target_health = true
  }
}

