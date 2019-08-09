variable "environment" {
}

variable "bucket_name" {
}

variable "distribution_cname" {
}

variable "acm_certificate_arn" {
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }

  versioning {
    enabled = true
  }

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

locals {
  s3_origin_id = "myS3Origin"
}

// Provider required to retrieve the certificate in aws-us-east-1
provider "aws" {
  alias = "aws-us-east-1"
  version = "~> 2.7"
  region = "us-east-1"
  profile = "aws_template"
}



resource "aws_cloudfront_distribution" "bucket_distribution" {
  provider = "aws.aws-us-east-1"
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = [var.distribution_cname]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
}

output "distribution_zone_id" {
  value = aws_cloudfront_distribution.bucket_distribution.hosted_zone_id
}

output "distribution_domain_name" {
  value = aws_cloudfront_distribution.bucket_distribution.domain_name
}

