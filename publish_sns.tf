data "archive_file" "zip_publish_sns" {
  type        = "zip"
  source_dir  = "${path.module}/publish_sns/"
  output_path = "${path.module}/publish_sns.zip"
}

resource "aws_lambda_function" "publish_sns" {
  filename      = "${path.module}/publish_sns.zip" 
  role          = aws_iam_role.publish_sns_lambda.arn

  function_name = join("-", [
    var.context,
    var.publish_sns_lambda_name
  ])

  source_code_hash = data.archive_file.zip_publish_sns.output_base64sha256

  handler = "publish_sns.lambda_handler"
  runtime = var.runtime
  depends_on = [data.archive_file.zip_publish_sns]

  memory_size = 128
  timeout     = 300

  tags = var.tags

  environment {
    variables = {
      region = var.region
      sns_topic_arn  = var.sns_topic_arn
      alarm_name = var.alarm_name
      periodic_rule_name = aws_cloudwatch_event_rule.trigger_publish_sns.name
    }
  }
}

resource "aws_iam_role" "publish_sns_lambda" {
  name = join("-", [
    var.context,
    var.publish_sns_lambda_name,
    "role"
  ])
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "publish_sns_lambda_execution_role_policy" {
  role       = aws_iam_role.publish_sns_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_cloudwatch_event_rule" "trigger_publish_sns" {

  name = join("-", [
    var.context,
    var.publish_sns_lambda_name,
    "policy"
  ])
  # Schedule expression to trigger periodic, e.g. "rate(15 minutes)" "rate(1 hour)"
  schedule_expression = var.periodic_schedule_expression
  state = "ENABLED"
}

resource "aws_cloudwatch_event_target" "publish_sns_target" {
  rule      = aws_cloudwatch_event_rule.trigger_publish_sns.name

  target_id = join("-", [
    var.context,
    var.publish_sns_lambda_name,
    "target"
  ])
  arn       = aws_lambda_function.publish_sns.arn
}

# Allow the EventBridge rule to invoke the Lambda function
resource "aws_lambda_permission" "allow_event_rule" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.publish_sns.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_publish_sns.arn
}

resource "aws_iam_policy" "publish_sns_lambda_pol" {
  name = join("-", [
    var.context,
    var.publish_sns_lambda_name,
    "policy"
  ])

  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  #policy      = data.template_file.json_template.rendered

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
 
      {
        Effect = "Allow",
        Action = [
          "events:*",
          "events:EnableRule",
          "events:DisableRule",
          "events:ListRules"
        ],
        Resource = [ "*"
          #"${aws_cloudwatch_event_rule.daily_12am_pst.arn}",
          #"${aws_cloudwatch_event_rule.in_fewmins.arn}",
          #"${aws_cloudwatch_event_rule.daily_12am_pdt.arn}"
        ]
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "cloudwatch:DisableAlarmActions",
          "cloudwatch:*"
        ],
        "Resource" = [
          "*"
          #"arn:aws:s3:::${local.rnp}-${var.obd_report_conf.s3_bkt_name}${var.s3_suffix}",
          #"arn:aws:s3:::${local.rnp}-${var.obd_report_conf.s3_bkt_name}${var.s3_suffix}/*"
        ]
      },
      {
        "Effect"   = "Allow",
        "Action"   = ["sns:Publish", "sns:*"],
        "Resource" = var.sns_topic_arn

        #"Resource" = "${aws_sns_topic.rpt_sns_topic.arn}"
      }
    ]
  })
  #depends_on = [aws_sns_topic.mon_sns_topic]
}

resource "aws_iam_role_policy_attachment" "publish_sns_pol_attach" {
  role       = aws_iam_role.publish_sns_lambda.name
  policy_arn = aws_iam_policy.publish_sns_lambda_pol.arn
}

# # Define the external data source in Terraform

# data "external" "publish_sns_current_time" {
#   program = ["bash", "${path.module}/get_time2.sh"]
# }

# # output "current_time" {
# #   value = data.external.current_time.result["current_time"]
# # }

# output "publish_sns_future_time" {
#   value = data.external.current_time.result["future_time"]
# }


/*
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowSNSInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.publish_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.mon_sns_topic.arn
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.mon_sns_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.publish_sns.arn
}
*/

# output "min" {
#   value = local.minute
# }
# output "hour" {
#   value = local.hour
# }

# Regular hours
# resource "aws_cloudwatch_event_rule" "enable_alarm" {
#   name                = "${local.rnp}-enable-alarm"

#   schedule_expression = "cron(${local.minute} ${local.hour} * * ? *)" # Runs at specified time
#   state               = "DISABLED"
# }


# locals {
#   time_parts = split(":", data.external.current_time.result["future_time"] )
#   hour       = local.time_parts[0]
#   minute     = local.time_parts[1]
# }


# # daylight saving
# resource "aws_cloudwatch_event_rule" "disable_alarm" {
#   name                = "${local.rnp}-${var.obd_report_conf.lambda_func_name}-daily-12am-pdt"
#   schedule_expression = "cron(0 7 * * ? *)" # Runs at 7 AM UTC every day
#   state               = "DISABLED"
# }

# resource "aws_iam_role_policy_attachment" "events_policy" {
#   role       = aws_iam_role.lambda_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
# }