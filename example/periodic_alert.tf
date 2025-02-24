
module "periodic_alert" {
  source = "../"
  #source = "git::https://github.com/ypant/terraform-aws-periodic-alert.git?ref=v0.0.1"

  region = "us-west-2"
  tags   = local.tags

  sns_topic_arn = aws_sns_topic.mon_sns_topic.arn
  alarm_name    = "${local.prefix_noenv}-alarm-${var.mon_conf.alarm_name}"

  periodic_schedule_expression = "rate(15 minutes)"
}
