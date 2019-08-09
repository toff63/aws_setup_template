#---------------------------------------------------
# S3 buckets and associated policies to access them
#---------------------------------------------------

variable "environment" {
}

variable "product_name" {
}

variable "api_role_id" {
}

resource "aws_s3_bucket" "picture" {
  bucket = "${var.product_name}-picture-${var.environment}"
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT"]
    allowed_origins = ["*"]
  }

  versioning {
    enabled = true
  }

  tags = {
    Name        = "${var.product_name}-picture-${var.environment}"
    Environment = var.environment
  }
}

data "template_file" "S3PictureAccessPolicy" {
  template = file("${path.module}/BucketAccessPolicy.json")

  vars = {
    bucket = aws_s3_bucket.picture.bucket
  }
}

resource "aws_iam_role_policy" "s3-picture-access-policy" {
  name   = "${aws_s3_bucket.picture.bucket}-AccessPolicy"
  policy = data.template_file.S3PictureAccessPolicy.rendered
  role   = var.api_role_id
}

output "picture_bucket_regional_domain_name" {
  value = aws_s3_bucket.picture.bucket_regional_domain_name
}

output "picture_bucket_name" {
  value = "${var.product_name}-picture-${var.environment}"
}

