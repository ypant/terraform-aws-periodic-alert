resource "aws_iam_role" "mon_lambda_role" {
  name = join("-", [
    local.prefix,
    var.mon_conf.lambda_func_name,
    "role"
  ])
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com",
      },
    }],
  })
}

resource "aws_sns_topic" "mon_sns_topic" {
  name = join("-", [
    local.prefix,
    var.mon_conf.sns_topic_name,
    "topic"
    ]
  )
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email_subscription" {
  count     = length(var.email_endpoints)
  topic_arn = aws_sns_topic.mon_sns_topic.arn
  protocol  = "email"
  endpoint  = var.email_endpoints[count.index]
  confirmation_timeout_in_minutes = 10080 # 7 days
}

resource "aws_sns_topic_subscription" "sms_subscription" {
  count                           = length(var.phone_numbers)
  topic_arn                       = aws_sns_topic.mon_sns_topic.arn
  protocol                        = "sms"
  endpoint                        = var.phone_numbers[count.index]
  confirmation_timeout_in_minutes = 10080
}

resource "aws_iam_policy" "mon_lambda_pol" {
  name = join("-", [
    local.prefix,
    var.mon_conf.lambda_func_name,
    "policy"
    ]
  )
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Action" = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" = "arn:aws:logs:*:*:*",
        "Effect"   = "Allow"
      },
      {
        "Effect"   = "Allow",
        "Action"   = ["sns:Publish"],
        "Resource" = "${aws_sns_topic.mon_sns_topic.arn}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:PutMetricData"
        ],
        "Resource" : "*"
      }
    ]
  })
  depends_on = [aws_sns_topic.mon_sns_topic]
}

resource "aws_iam_role_policy_attachment" "mon_pol_attach" {
  role       = aws_iam_role.mon_lambda_role.name
  policy_arn = aws_iam_policy.mon_lambda_pol.arn
}
