#------------------------------------
# Cloudfront distributions
#------------------------------------

variable "environment" {
}

variable "picture_bucket_regional_domain_name" {
}

locals {
  s3_origin_id = "picture-${var.environment}"
}

resource "aws_cloudfront_distribution" "s3_picture_distribution" {
  origin {
    domain_name = var.picture_bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }

  enabled         = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET", "OPTIONS"]
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

  tags = {
    Environment = var.environment
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

