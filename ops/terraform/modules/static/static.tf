variable "bucket_name" {
}

variable "domain" {
}

variable "environment" {
}

variable "domain_zone_id" {
}

variable "acm_certificate_arn" {
}

module "static_bucket" {
  source = "./bucket"

  bucket_name         = var.bucket_name
  environment         = var.environment
  distribution_cname  = var.domain
  acm_certificate_arn = var.acm_certificate_arn
}

module "static_dns" {
  source = "./domain"

  zone_id               = var.domain_zone_id
  domain_name           = var.domain
  target_domain_name    = module.static_bucket.distribution_domain_name
  target_bucket_zone_id = module.static_bucket.distribution_zone_id
}

