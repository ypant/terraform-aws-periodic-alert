variable "sns_topic_arn" {
  description = "SNS topic name where current alarm notifications are being published."
  type = string
}
variable "alarm_name" {
  description = "Alarm name for which periodic notifications are to be enabled."
  type = string
}

variable "periodic_schedule_expression" {
  description = "Frequency of notification repeats."
  default = "rate(15 minutes)"
  type = string
}

variable "context" {
  description = "Resources created by this module will use this parameter as a prefix."
  default = "peri-alert" # periodic alert
  type = string
}

variable "check_alarm_status_lambda_name" {
  description = "name of the check alarm status lambda function"
  default = "check-alarm-status"
  type = string
}

variable "runtime" {
  description = "Version of python runtime for lambda"
  default = "python3.10"
  type = string
}

variable "tags" {
  description = ""
  default = {
    name = "generate-periodic-alert"
  }
}

variable "region" {
  description = "region"
  default = "us-east-1"
}


variable "publish_sns_lambda_name" {
  description = "name of the check alarm status lambda function"
  default = "publish-sns"
}

