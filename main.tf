


resource "aws_launch_configuration" "pscloud-lc" {
  name                      = "${var.pscloud_company}_lc_${var.pscloud_env}"
  image_id                  = var.pscloud_ami
  instance_type             = var.pscloud_ec2_type
  security_groups           = [ var.pscloud_sec_gr ]
  key_name                  = var.pscloud_key_name
}


resource "aws_autoscaling_group" "pscloud-asg" {
  name                      = "${var.pscloud_company}_asg_${var.pscloud_env}"
  max_size                  = var.pscloud_max_size
  min_size                  = var.pscloud_min_size
  health_check_grace_period = 60
  health_check_type         = "ELB"
  desired_capacity          = var.pscloud_min_size
  force_delete              = true
  launch_configuration      = aws_launch_configuration.pscloud-lc.name
  vpc_zone_identifier       = var.pscloud_subnets_ids.*.id

  tag {
    key                     = "Name"
    value                   = "${var.pscloud_company}_ec2_asg_${var.pscloud_env}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "pscloud-asg-attachment" {
  count                     = var.pscloud_attachment_true ? 1 : 0

  autoscaling_group_name    = aws_autoscaling_group.pscloud-asg.id
  alb_target_group_arn      = var.pscloud_lb_tg_arn
}

resource "aws_autoscaling_policy" "pscloud-scale-up" {
  name                      = "${var.pscloud_company}-asg-policy-scale-up-${var.pscloud_env}"
  scaling_adjustment        = var.pscloud_scale_adjustment_scale_up
  adjustment_type           = var.pscloud_scale_adjustment_type
  policy_type               = var.pscloud_scale_policy_type
  cooldown                  = var.pscloud_scale_cooldown
  autoscaling_group_name = aws_autoscaling_group.pscloud-asg.name
}

resource "aws_autoscaling_policy" "pscloud-scale-down" {
  name                      = "${var.pscloud_company}-asg-policy-scale-down-${var.pscloud_env}"
  scaling_adjustment        = var.pscloud_scale_adjustment_scale_down
  adjustment_type           = var.pscloud_scale_adjustment_type
  policy_type               = var.pscloud_scale_policy_type
  cooldown                  = var.pscloud_scale_cooldown
  autoscaling_group_name    = aws_autoscaling_group.pscloud-asg.name
}

resource "aws_cloudwatch_metric_alarm" "pscloud-cloudwatch-cpu-high" {
  alarm_name                = "${var.pscloud_company}-pscloud-cloudwatch-cpu-high-alarm-${var.pscloud_env}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 80

  dimensions = {
    AutoScalingGroupName    = aws_autoscaling_group.pscloud-asg.name
  }

  alarm_actions             = [ aws_autoscaling_policy.pscloud-scale-up.arn ]
}

resource "aws_cloudwatch_metric_alarm" "pscloud-cloudwatch-cpu-low" {
  alarm_name                = "${var.pscloud_company}-pscloud-cloudwatch-cpu-low-alarm-${var.pscloud_env}"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 40

  dimensions = {
    AutoScalingGroupName    = aws_autoscaling_group.pscloud-asg.name
  }

  alarm_actions             = [ aws_autoscaling_policy.pscloud-scale-down.arn ]
}