#--------------------------------------
# Load balancer on top of API instances
#--------------------------------------

variable "environment" {
}

variable "vpc_id" {
}

variable "public_subnet_ids" {
}

variable "certificate_arn" {
}

variable "ip_address_type" {
}

variable "remote_access_sg" {
}

variable "health_path" {
}

variable "api_client_sg" {
}

variable "port" {
}

variable "alb_name" {
}

resource "aws_lb_target_group" "api" {
  name                 = "${var.environment}-${var.alb_name}"
  port                 = var.port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 120

  health_check {
    interval            = 30
    healthy_threshold   = 5
    unhealthy_threshold = 6
    timeout             = 5
    matcher             = 200
    path                = var.health_path
    port                = var.port
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb" "api" {
  name               = "${var.environment}-${var.alb_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.remote_access_sg]
  subnets            = split(",", var.public_subnet_ids)
  ip_address_type    = var.ip_address_type

  enable_deletion_protection = true

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = var.certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.api.arn
    type             = "forward"
  }
}

output "dns_name" {
  value = aws_lb.api.dns_name
}

output "zone_id" {
  value = aws_lb.api.zone_id
}

output "target_group_arn" {
  value = aws_lb_target_group.api.arn
}

output "alb_arn" {
  value = aws_lb.api.arn
}

