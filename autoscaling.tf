# launch EC2 for Data Engineering Module as part of the autoscaling group
resource "aws_launch_configuration" "example" {
  name                 = "example-launch-config"
  image_id             = data.aws_ssm_parameter.qiime2Ami.value
  instance_type        = "t3.large"
  security_groups      = [aws_security_group.sg.id]
  associate_public_ip_address = false
  key_name             = var.generated_key_name
  user_data            = <<EOF
  #!/bin/bash
  sudo su
  yum update -y
  chmod 600 /home/qiime2/.s3fs-creds
  s3fs qiime2storage /home/qiime2/qiime2storage  -o passwd_file=$HOME/.s3fs-creds,nonempty,rw,allow_other,mp_umask=002,uid=1001,gid=1001 -o url=http://s3.us-west-2.amazonaws.com,endpoint=us-west-2,use_path_request_style
  screen -S dataengineering
  cd DataEngineering/
  source env/bin/activate
  python3 main.py 
  EOF
  iam_instance_profile     = aws_iam_instance_profile.example.name
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "example" {
  name                 = "example-autoscaling-group"
  launch_configuration = "${aws_launch_configuration.example.name}"
  min_size             = 1
  max_size             = 5
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.private_subnet.id]
  health_check_type    = "EC2"

  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "example-instance"
    propagate_at_launch = true
  }

}

resource "aws_autoscaling_policy" "example_scaling_policy_up" {
  name                   = "example-scaling-policy-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.example.name}"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "example_cpu_utilization_high" {
  alarm_name          = "example-cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.example.name}"
  }
  alarm_actions = [aws_autoscaling_policy.example_scaling_policy_up.arn]
}

resource "aws_autoscaling_policy" "example_scaling_policy_down" {
  name                   = "example-scaling-policy-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.example.name}"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "example-cpu-utilization-low" {
  alarm_name          = "example-cpu-utilization-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.example.name}"
  }
  alarm_actions = [aws_autoscaling_policy.example_scaling_policy_down.arn]
}


resource "aws_iam_instance_profile" "example" {
  name = "example-instance-profile"
  role = aws_iam_role.example.name
}

resource "aws_iam_role" "example" {
  name = "example-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "example-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:Get*",
            "s3:List*"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

