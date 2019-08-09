#--------------------------------------
# Security groups used by API
#--------------------------------------

variable "environment" {
}

variable "vpc_id" {
}

variable "name" {
}

variable "bastion_sg" {
}

variable "authorized_cidrs" {
  type    = list(string)
  default = []
}

variable "ipv6_authorized_cidrs" {
  type    = list(string)
  default = []
}

resource "aws_security_group" "remote_access" {
  name        = "api_remote_access_${var.environment}"
  vpc_id      = var.vpc_id
  description = "Access dev API from office and home"

  tags = {
    Name        = "API_Remote_access"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = var.authorized_cidrs
    ipv6_cidr_blocks = var.ipv6_authorized_cidrs
    description      = "Remote access"
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "api" {
  name        = "${var.name}_${var.environment}"
  vpc_id      = var.vpc_id
  description = "API"

  tags = {
    Name        = var.name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    protocol        = "tcp"
    from_port       = 4001
    to_port         = 4003
    security_groups = [aws_security_group.remote_access.id]
    description     = "Remote access"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 4369
    to_port     = 4369
    self        = true
    description = "EPMD port"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 9100
    to_port     = 9155
    self        = true
    description = "Erlang intercluster"
  }
  ingress {
    protocol        = "tcp"
    from_port       = 4001
    to_port         = 4003
    security_groups = [aws_security_group.api_client.id]
    description     = "Remote access"
  }

  ingress {
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = [var.bastion_sg]
    description     = "Bastion"
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "api_client" {
  name        = "${var.name}_client_${var.environment}"
  vpc_id      = var.vpc_id
  description = "API"

  tags = {
    Name        = var.name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "api_sg" {
  value = aws_security_group.api.id
}

output "remote_access_sg" {
  value = aws_security_group.remote_access.id
}

output "api_client_sg" {
  value = aws_security_group.api_client.id
}

