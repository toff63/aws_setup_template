variable "domain"             { }
variable "region"             { }
variable "access_key"         { }
variable "secret_key"         { }
variable "app_name"           { }
variable "certificate_domain" { }

provider "aws" {
  version = "~> 2.7"
  region = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  profile = "aws_template"
}

// Provider required to retrieve the certificate in aws-us-east-1
provider "aws" {
  alias = "aws-us-east-1"
  version = "~> 2.7"
  region = "us-east-1"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  profile = "aws_template"
}

terraform {
  backend "s3" {
    bucket = "terraform-remote-state-my-product"
    key="aws_global/terraform.tfstate"
    encrypt = true
    dynamodb_table = "terraform-my-product-lock"
  }
}

data "aws_route53_zone" "zone" {
  name = "${var.domain}"
}


data "aws_acm_certificate" "cloudfront" {
  provider = "aws.aws-us-east-1"
  domain   = "${var.certificate_domain}"
}

data "aws_acm_certificate" "regional" {
  domain   = "${var.certificate_domain}"
}

resource "aws_iam_role" "PackerRole" {
  name = "PackerRole"
  assume_role_policy = "${file("PackerRole.json")}"
}

resource "aws_iam_instance_profile" "packer_profile" {
  name = "packer_profile"
  role = "${aws_iam_role.PackerRole.name}"
}

resource "aws_iam_role_policy" "PackerPolicy" {
  name = "PackerPolicy"
  role = "${aws_iam_role.PackerRole.id}"

  policy = "${file("PackerPolicy.json")}"
}

module "release" {
  source = "../../modules/release"

  packer-role-name = "${aws_iam_role.PackerRole.name}"
  product          = "${var.app_name}"
}


output "zone_id" { value = "${data.aws_route53_zone.zone.zone_id}" }
output "cloudfront_certificate_arn" { value = "${data.aws_acm_certificate.cloudfront.arn}" }
output "domain" { value = "${var.domain}" }
output "app_name" { value = "${var.app_name}" }
output "packer-role-name" { value = "${aws_iam_role.PackerRole.name}" }
output "regional_certificate_arn" { value = "${data.aws_acm_certificate.regional.arn}" }
