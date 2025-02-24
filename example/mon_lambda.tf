data "archive_file" "mon_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/mon_lambda/"
  output_path = "${path.module}/mon_lambda.zip"
}

resource "aws_lambda_function" "mon_lambda" {
  filename      = "${path.module}/mon_lambda.zip"

  function_name = join("-", [
    local.prefix,
    var.mon_conf.lambda_func_name
  ])
  role          = aws_iam_role.mon_lambda_role.arn

  source_code_hash = data.archive_file.mon_lambda_zip.output_base64sha256
  handler          = var.mon_conf.lambda_func_handler
  runtime          = var.mon_conf.lambda_func_runtime
  memory_size      = var.mon_conf.lambda_memory_mb
  timeout          = 300
  tags             = local.tags

  depends_on = [ aws_iam_role_policy_attachment.mon_pol_attach,
    data.archive_file.mon_lambda_zip ]

  environment {
    variables = {
      sns_topic_arn    = aws_sns_topic.mon_sns_topic.arn
      debug_level      = var.mon_conf.debug_level
      metric_name      = var.mon_conf.metric_name
      metric_namespace = var.mon_conf.metric_namespace
      metric_dim_name  = var.mon_conf.metric_dim_name
      app_urls         = jsonencode(var.app_urls)
      region           = var.mon_conf.region
    }
  }
}

resource "aws_cloudwatch_log_group" "mon_log_group" {

  name = join("-", [
    "/aws/lambda/${local.prefix}",
    var.mon_conf.lambda_func_name,
    "loggroup"
  ])

  retention_in_days = var.mon_conf.cw_log_retention

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
  }
}

resource "aws_cloudwatch_event_target" "periodic_mon_task" {
  rule      = aws_cloudwatch_event_rule.periodic_evt_rule.name
  target_id = "${local.prefix}-${var.mon_conf.lambda_func_name}-evt-target"
  arn       = aws_lambda_function.mon_lambda.arn
}

resource "aws_cloudwatch_event_rule" "periodic_evt_rule" {
  name                = "${local.prefix}-rule-${var.mon_conf.lambda_func_name}-regular"
  schedule_expression = var.mon_conf.lambda_schedule
  state               = "ENABLED"
}

resource "aws_lambda_permission" "mon_lambda_permission" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mon_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.periodic_evt_rule.arn
}
