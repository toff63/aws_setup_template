variable "name" {
}

variable "full_name" {
}

variable "region" {
}

variable "access_key" {
}

variable "secret_key" {
}

variable "sub_domain" {
}

variable "vpc_cidr" {
}

variable "azs" {
}

variable "private_subnets" {
}

variable "public_subnets" {
}

variable "bastion_instance_type" {
}

variable "bastion_ami_id" {
}

variable "bastion_public_key" {
}

variable "bastion_ingress_cidr" {
}

variable "api_ingress_cidr" {
}

# Deploy
variable "version_green" {
}

variable "version_blue" {
}

variable "api_public_key" {
}

variable "api_instance_type" {
}

variable "api_cluster_size" {
  default = "4"
}

variable "domain_name" {
}

provider "aws" {
  version    = "~> 2.7"
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  profile    = "aws_template"
}

terraform {
  backend "s3" {
    bucket         = "terraform-remote-state-my-product"
    key            = "eu-west-1-prod/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-my-product-lock"
  }
}

data "terraform_remote_state" "aws_global" {
  backend = "s3"

  config = {
    bucket         = "terraform-remote-state-my-product"
    key            = "aws_global/terraform.tfstate"
    region         = var.region
    access_key     = var.access_key
    secret_key     = var.secret_key
    dynamodb_table = "terraform-my-product-lock"
  }
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "KP_bastion_${var.name}"
  public_key = var.bastion_public_key

  lifecycle {
    create_before_destroy = true
  }
}

module "network" {
  source = "../../modules/network"

  name            = var.name
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  region          = var.region
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  key_name        = aws_key_pair.bastion_key.key_name
  sub_domain      = var.sub_domain
  route_zone_id   = data.terraform_remote_state.aws_global.outputs.zone_id
  root_domain     = data.terraform_remote_state.aws_global.outputs.domain

  bastion_instance_type = var.bastion_instance_type
  bastion_ami_id        = var.bastion_ami_id
  bastion_ingress_cidr  = var.bastion_ingress_cidr
}

module "static" {
  source = "../../modules/static"

  bucket_name         = "${data.terraform_remote_state.aws_global.outputs.app_name}-static-${var.name}"
  domain              = "static-${var.name}.${data.terraform_remote_state.aws_global.outputs.domain}"
  environment         = var.name
  domain_zone_id      = data.terraform_remote_state.aws_global.outputs.zone_id
  acm_certificate_arn = data.terraform_remote_state.aws_global.outputs.cloudfront_certificate_arn
}

module "api" {
  source = "../../modules/api"

  lb_ip_address_type     = "dualstack"
  vpc_id                 = module.network.vpc_id
  domain_name            = var.domain_name
  certificate_arn        = data.terraform_remote_state.aws_global.outputs.regional_certificate_arn
  public_subnet_ids      = module.network.public_subnet_ids
  environment            = var.name
  bastion_sg             = module.network.bastion_sg
  private_subnets        = module.network.private_subnet_ids
  product_name           = data.terraform_remote_state.aws_global.outputs.app_name
  zone_id                = data.terraform_remote_state.aws_global.outputs.zone_id
  internal_zone_id       = module.network.internal_dns_zone_id
  name                   = "api"
  authorized_cidrs       = ["0.0.0.0/0"]
  ipv6_authorized_cidrs  = ["::/0"]
  redis_node_count       = 2
  redis_node_type        = "cache.m4.large"
  api_rate_limit_value   = "2000"
}

module "deploy_api_blue" {
  source = "../../modules/deploy_bg"

  environment                    = var.name
  api_version_to_deploy          = var.version_blue
  api_public_key                 = var.api_public_key
  instance_type                  = var.api_instance_type
  ami_environment                = var.full_name
  private_subnets                = module.network.private_subnet_ids
  api_sg                         = [module.api.api_sg]
  api_instance_profile           = module.api.api_instance_profile
  api_role                       = module.api.api_role_id
  cluster_size                   = var.api_cluster_size
  cluster_size_max               = var.api_cluster_size * 5
  autoscaling_cpu_threshold_high = "60"
  autoscaling_cpu_threshold_low  = "30"
  color                          = "blue"
}

module "deploy_api_green" {
  source = "../../modules/deploy_bg"

  environment                    = var.name
  api_version_to_deploy          = var.version_green
  api_public_key                 = var.api_public_key
  instance_type                  = var.api_instance_type
  ami_environment                = var.full_name
  private_subnets                = module.network.private_subnet_ids
  api_sg                         = [module.api.api_sg]
  api_instance_profile           = module.api.api_instance_profile
  api_role                       = module.api.api_role_id
  cluster_size                   = var.api_cluster_size
  cluster_size_max               = var.api_cluster_size * 5
  autoscaling_cpu_threshold_high = "60"
  autoscaling_cpu_threshold_low  = "30"
  color                          = "green"
}
