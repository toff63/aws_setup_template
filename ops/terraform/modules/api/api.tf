#--------------------------------------
# Infrstructure needed to deploy API
#--------------------------------------

variable "user" {
  default = ""
}

variable "zone_id" {
}

variable "domain_name" {
}

variable "certificate_arn" {
}

variable "public_subnet_ids" {
}

variable "private_subnets" {
}

variable "vpc_id" {
}

variable "environment" {
}

variable "bastion_sg" {
}

variable "product_name" {
}

variable "name" {
}

variable "authorized_cidrs" {
  type    = list(string)
  default = []
}

variable "ipv6_authorized_cidrs" {
  type    = list(string)
  default = []
}

variable "redis_node_type" {
}

variable "redis_node_count" {
}

variable "api_rate_limit_value" {
}

variable "lb_ip_address_type" {
  default = "ipv4"
}

variable "internal_zone_id" {
}

module "load_balancer_api" {
  source = "./load_balancer"

  environment       = var.environment
  vpc_id            = var.vpc_id
  ip_address_type   = var.lb_ip_address_type
  public_subnet_ids = var.public_subnet_ids
  certificate_arn   = var.certificate_arn
  remote_access_sg  = module.security_group.remote_access_sg
  port              = "4001"
  health_path       = "/v1/"
  alb_name          = "api${var.user}"
  api_client_sg     = module.security_group.api_client_sg
}

module "dns" {
  source = "./dns"

  zone_id         = var.zone_id
  domain_name     = "${var.domain_name}${var.user}"
  aws_lb_dns_name = module.load_balancer_api.dns_name
  aws_lb_zone_id  = module.load_balancer_api.zone_id
}

module "redis" {
  source = "./redis"

  environment     = var.environment
  vpc_id          = var.vpc_id
  private_subnets = var.private_subnets
  api_sg          = module.security_group.api_sg
  node_type       = var.redis_node_type
  node_count      = var.redis_node_count
}

module "security_group" {
  source = "./security_group"

  environment                 = var.environment
  vpc_id                      = var.vpc_id
  name                        = var.name
  bastion_sg                  = var.bastion_sg
  authorized_cidrs            = var.authorized_cidrs
  ipv6_authorized_cidrs       = var.ipv6_authorized_cidrs
}

module "iam" {
  source = "./iam"

  environment      = var.environment
  internal_zone_id = var.internal_zone_id
}

module "s3" {
  source = "./s3"

  environment  = var.environment
  product_name = var.product_name
  api_role_id  = module.iam.api_role_id
}

module "cloudfront" {
  source = "./cloudfront"

  environment                         = var.environment
  picture_bucket_regional_domain_name = module.s3.picture_bucket_regional_domain_name
}

output "api_sg" {
  value = module.security_group.api_sg
}

output "api_instance_profile" {
  value = module.iam.api_instance_profile
}

output "api_role_id" {
  value = module.iam.api_role_id
}

output "api_target_group_arn" {
  value = [module.load_balancer_api.target_group_arn]
}

output "api_client_security_group" {
  value = module.security_group.api_client_sg
}

output "picture_bucket_name" {
  value = module.s3.picture_bucket_name
}

