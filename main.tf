


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
  count = (var.pscloud_attachment_true == true ? 1 : 0)

  autoscaling_group_name      = aws_autoscaling_group.pscloud-asg.id
  alb_target_group_arn        = var.pscloud_lb_tg_arn
  //elb                         = var.pscloud_elb_id
}