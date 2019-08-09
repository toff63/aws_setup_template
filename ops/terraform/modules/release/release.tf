variable "packer-role-name" {
}

variable "product" {
}

module "release" {
  source = "./s3"

  bucket           = "${var.product}-release"
  packer-role-name = var.packer-role-name
}

module "configuration" {
  source = "./s3"

  bucket           = "${var.product}-configuration"
  packer-role-name = var.packer-role-name
}

