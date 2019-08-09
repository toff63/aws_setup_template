#---------------------------------------------------
# API role and policy
#---------------------------------------------------

variable "environment" {
}

variable "internal_zone_id" {
}

resource "aws_iam_role" "ApiRole" {
  name               = "ApiRole_${var.environment}"
  assume_role_policy = file("${path.module}/ApiRole.json")
}

resource "aws_iam_instance_profile" "api_profile" {
  name = "api_profile_${var.environment}"
  role = aws_iam_role.ApiRole.name
}

resource "aws_iam_policy" "describe_access_policy" {
  name   = "DescribeInstancesAndTagsPolicy_${var.environment}"
  policy = file("${path.module}/describe_instances_access_policy.json")
}

data "template_file" "update_route_53_policy" {
  template = file("${path.module}/update_dns.json")

  vars = {
    zone_id = var.internal_zone_id
  }
}

resource "aws_iam_policy" "update_route_53" {
  name   = "UpdateInternalRoute53Records_${var.environment}"
  policy = data.template_file.update_route_53_policy.rendered
}

resource "aws_iam_role_policy_attachment" "attach-update-route-53-policy" {
  role       = aws_iam_role.ApiRole.name
  policy_arn = aws_iam_policy.update_route_53.arn
}

resource "aws_iam_role_policy_attachment" "attach-describe-access-policy" {
  role       = aws_iam_role.ApiRole.name
  policy_arn = aws_iam_policy.describe_access_policy.arn
}

output "api_role_id" {
  value = aws_iam_role.ApiRole.id
}

output "api_instance_profile" {
  value = aws_iam_instance_profile.api_profile.arn
}

