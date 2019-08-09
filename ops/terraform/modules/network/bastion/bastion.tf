#--------------------------------------------------------------
# This module creates all resources necessary for a Bastion
# host
#--------------------------------------------------------------

variable "name" {
  default = "bastion"
}

variable "vpc_id" {
}

variable "vpc_cidr" {
}

variable "region" {
}

variable "public_subnet_ids" {
}

variable "key_name" {
}

variable "instance_type" {
}

variable "environment" {
}

variable "ami_id" {
}

variable "bastion_ingress_cidr" {
}

resource "aws_security_group" "bastion" {
  name        = var.name
  vpc_id      = var.vpc_id
  description = "Bastion security group"

  tags = {
    Name        = var.name
    Environment = var.environment
  }
  lifecycle {
    create_before_destroy = true
  }

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
    description = "VPC cidr"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = var.bastion_ingress_cidr
    description = "My IP"
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = element(split(",", var.public_subnet_ids), 0)
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = {
    Name        = var.name
    Environment = var.environment
  }
  lifecycle {
    create_before_destroy = true
  }
}

output "user" {
  value = "ubuntu"
}

output "private_ip" {
  value = aws_instance.bastion.private_ip
}

output "public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_sg" {
  value = aws_security_group.bastion.id
}

