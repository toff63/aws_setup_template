#--------------------------------------
# Redis clusters
#--------------------------------------

variable "environment" {
}

variable "private_subnets" {
}

variable "vpc_id" {
}

variable "api_sg" {
}

variable "node_type" {
}

variable "node_count" {
}

resource "aws_elasticache_cluster" "phone-redis" {
  count = var.node_count > 0 ? 1 : 0
  cluster_id = substr(
    "cache-${var.environment}",
    0,
    min(20, length("cache-${var.environment}")),
  )
  engine               = "redis"
  engine_version       = "5.0.4"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-${var.environment}"
  subnet_ids = split(",", var.private_subnets)
}

resource "aws_security_group" "redis" {
  name        = "redis-${var.environment}"
  vpc_id      = var.vpc_id
  description = "Redis"

  tags = {
    Name        = "redis"
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

