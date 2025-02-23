

data "archive_file" "zip_check_alarm_status" {
  type        = "zip"
  source_dir  = "${path.module}/check_alarm_status/"
  output_path = "${path.module}/check_alarm_status.zip"
}

resource "aws_lambda_function" "check_alarm_status" {
  filename      = "${path.module}/check_alarm_status.zip" # lambda_src/lambda_src.zip"

  function_name = join("-", [
    var.context,
    var.check_alarm_status_lambda_name
  ])

  role          = aws_iam_role.check_alarm_status_lambda.arn
  source_code_hash = data.archive_file.zip_check_alarm_status.output_base64sha256

  handler = "check_alarm_status.lambda_handler"
  runtime = var.runtime
  depends_on = [data.archive_file.zip_check_alarm_status]

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

resource "aws_iam_role" "check_alarm_status_lambda" {
  name = join("-", [
    var.context,
    var.check_alarm_status_lambda_name,
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

resource "aws_iam_role_policy_attachment" "lambda_execution_role_policy" {
  role       = aws_iam_role.check_alarm_status_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowSNSInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check_alarm_status.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.check_alarm_status.arn
}

resource "aws_iam_policy" "check_alarm_status_lambda_pol" {
  name = join("-", [
    var.context,
    var.check_alarm_status_lambda_name,
    "policy"
  ])

  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"

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
      }
    ]
  })
  #depends_on = [aws_sns_topic.mon_sns_topic]
}

resource "aws_iam_role_policy_attachment" "check_alarm_status_pol_attach" {
  role       = aws_iam_role.check_alarm_status_lambda.name
  policy_arn = aws_iam_policy.check_alarm_status_lambda_pol.arn
}
