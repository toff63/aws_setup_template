variable "bucket" {
}

variable "packer-role-name" {
}

resource "aws_s3_bucket" "releases" {
  bucket = var.bucket
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
    Name = var.bucket
  }
}

data "template_file" "S3GetAccessPolicy" {
  template = file("${path.module}/BucketGetAccessPolicy.json")
  vars = {
    bucket = var.bucket
  }
}

resource "aws_iam_policy" "s3-get-access-policy" {
  name   = "${var.bucket}GetPolicy"
  policy = data.template_file.S3GetAccessPolicy.rendered
}

resource "aws_iam_role_policy_attachment" "attach_to_packer_role" {
  role       = var.packer-role-name
  policy_arn = aws_iam_policy.s3-get-access-policy.arn
}

