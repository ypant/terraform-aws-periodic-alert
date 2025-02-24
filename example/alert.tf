
# create an alarm
module "metric_app_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.3"
  count   = var.mon_conf.create_alarm == true ? 1 : 0

  alarm_name          = "${local.prefix_noenv}-alarm-${var.mon_conf.alarm_name}"
  alarm_description   = "Applicaton Monitoring Status"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  threshold           = var.mon_conf.threshold
  period              = 60

  namespace   = var.mon_conf.metric_namespace
  metric_name = var.mon_conf.metric_name
  dimensions  = { "${var.mon_conf.metric_dim_name}" : "${var.app_urls[0]}" }
  statistic   = "Average"

  alarm_actions = [
    aws_sns_topic.mon_sns_topic.arn
  ]
  ok_actions = [
    aws_sns_topic.mon_sns_topic.arn
  ]

  tags = local.tags
}
