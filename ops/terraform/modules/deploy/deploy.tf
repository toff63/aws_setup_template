variable "environment" {
}

variable "api_version_to_deploy" {
}

variable "ami_environment" {
}

variable "api_public_key" {
}

variable "private_subnets" {
}

variable "api_sg" {
  type    = list(string)
  default = []
}

variable "instance_type" {
}

variable "api_instance_profile" {
}

variable "target_group_arn" {
  type    = list(string)
  default = []
}

variable "api_role" {
}

variable "cluster_size" {
  default = "1"
}

variable "cluster_size_max" {
  default = "1"
}

variable "autoscaling_cpu_threshold_high" {
  default = "60"
}

variable "autoscaling_cpu_threshold_low" {
  default = "30"
}

data "aws_ami" "ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:environment"
    values = [var.ami_environment]
  }

  filter {
    name   = "tag:component"
    values = ["api"]
  }
}

#-------------------------------
# ALB and ASG
#-------------------------------

# Key Pair
resource "aws_key_pair" "api-keypair" {
  key_name   = "KP_API_${var.environment}"
  public_key = var.api_public_key
}

# Launch template

resource "aws_launch_configuration" "api_launch_configuration" {
  lifecycle {
    create_before_destroy = true
  }

  name                 = "api-${var.environment}-${var.api_version_to_deploy}"
  image_id             = data.aws_ami.ami.image_id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.api-keypair.key_name
  security_groups      = var.api_sg
  iam_instance_profile = var.api_instance_profile
}

# Auto Scaling Group

resource "aws_autoscaling_group" "api_asg" {
  lifecycle {
    create_before_destroy = true
  }

  availability_zones        = ["eu-west-1b", "eu-west-1c", "eu-west-1a"]
  name                      = "api-${var.environment}-${var.api_version_to_deploy}"
  max_size                  = var.cluster_size_max
  min_size                  = var.cluster_size
  min_elb_capacity          = var.cluster_size
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = var.cluster_size
  force_delete              = true
  launch_configuration      = aws_launch_configuration.api_launch_configuration.name
  target_group_arns         = var.target_group_arn
  vpc_zone_identifier       = split(",", var.private_subnets)
  termination_policies      = ["OldestInstance", "Default"]

  tags = [
    {
      key                 = "Name"
      value               = "api-${var.api_version_to_deploy}-autoscaled"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = var.environment
      propagate_at_launch = true
    },
  ]
}

resource "aws_autoscaling_policy" "api_asg_scaling_policy_cpu_high" {
  policy_type            = "StepScaling"
  name                   = "cpu-high"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.api_asg.name

  step_adjustment {
    scaling_adjustment          = 1
    metric_interval_lower_bound = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_alarm" {
  alarm_name          = "awsec2-api-cpu-high-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.autoscaling_cpu_threshold_high

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.api_asg.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.api_asg_scaling_policy_cpu_high.arn]
}

resource "aws_autoscaling_policy" "api_asg_scaling_policy_cpu_low" {
  policy_type            = "StepScaling"
  name                   = "cpu-low"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.api_asg.name

  step_adjustment {
    scaling_adjustment          = -1
    metric_interval_upper_bound = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low_alarm" {
  alarm_name          = "awsec2-api-cpu-low-${var.environment}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.autoscaling_cpu_threshold_low

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.api_asg.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.api_asg_scaling_policy_cpu_low.arn]
}

