#--------------------------------------------------------------
# This module creates all networking resources
#--------------------------------------------------------------

variable "name" {
}

variable "vpc_cidr" {
}

variable "azs" {
}

variable "region" {
}

variable "private_subnets" {
}

variable "public_subnets" {
}

variable "sub_domain" {
}

variable "route_zone_id" {
}

variable "key_name" {
}

variable "bastion_ami_id" {
}

variable "root_domain" {
}

variable "bastion_instance_type" {
}

variable "bastion_ingress_cidr" {
}

module "vpc" {
  source = "./vpc"

  name        = "${var.name}-vpc"
  cidr        = var.vpc_cidr
  environment = var.name
}

module "vpc_endpoint" {
  source            = "./vpc_endpoint"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.public_subnet.subnet_ids
  region            = var.region
  route_table = concat(
    [module.public_subnet.public_route_table_id],
    module.private_subnet.private_route_table_id,
  )
}

module "public_subnet" {
  source = "./public_subnet"

  name            = "${var.name}-public"
  vpc_id          = module.vpc.vpc_id
  cidrs           = var.public_subnets
  ipv6_cidr_block = module.vpc.vpc_ipv6_cidr
  azs             = var.azs
  environment     = var.name
}

module "bastion" {
  source = "./bastion"

  name                 = "${var.name}-bastion"
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = module.vpc.vpc_cidr
  region               = var.region
  public_subnet_ids    = module.public_subnet.subnet_ids
  key_name             = var.key_name
  instance_type        = var.bastion_instance_type
  ami_id               = var.bastion_ami_id
  environment          = var.name
  bastion_ingress_cidr = var.bastion_ingress_cidr
}

module "nat" {
  source = "./nat"

  name              = "${var.name}-nat"
  azs               = var.azs
  public_subnet_ids = module.public_subnet.subnet_ids
}

module "private_subnet" {
  source = "./private_subnet"

  name   = "${var.name}-private"
  vpc_id = module.vpc.vpc_id
  cidrs  = var.private_subnets
  azs    = var.azs

  nat_gateway_ids = module.nat.nat_gateway_ids
  environment     = var.name
}

module "private_dns" {
  source = "./dns"

  vpc_id      = module.vpc.vpc_id
  domain      = var.root_domain
  environment = var.name
}

resource "aws_network_acl" "acl" {
  vpc_id = module.vpc.vpc_id
  subnet_ids = concat(
    split(",", module.public_subnet.subnet_ids),
    split(",", module.private_subnet.subnet_ids),
  )

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol        = "-1"
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol        = "-1"
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  tags = {
    Name        = "${var.name}-all"
    Environment = var.name
  }
}

# VPC endpoint
output "s3_prefix_list_id" {
  value = module.vpc_endpoint.s3_prefix_list_id
}

# VPC
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr
}

# Subnets
output "public_subnet_ids" {
  value = module.public_subnet.subnet_ids
}

output "private_subnet_ids" {
  value = module.private_subnet.subnet_ids
}

# Bastion
output "bastion_user" {
  value = module.bastion.user
}

output "bastion_private_ip" {
  value = module.bastion.private_ip
}

output "bastion_public_ip" {
  value = module.bastion.public_ip
}

output "bastion_sg" {
  value = module.bastion.bastion_sg
}

# NAT
output "nat_gateway_ids" {
  value = module.nat.nat_gateway_ids
}

output "internal_dns_zone_id" {
  value = module.private_dns.internal_dns_zone_id
}

