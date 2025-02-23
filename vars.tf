variable "context" {
  description = "an identifier that is used to identiy created by this module. This vill will prefix all names used."
  default = "peri-alert" # periodic alert
}

variable "check_alarm_status_lambda_name" {
  description = "name of the check alarm status lambda function"
  default = "check-alarm-status"
}

variable "runtime" {
  default = "python3.10"
}

variable "tags" {
  default = {
    name = "generate-periodic-alert"
  }
}

variable "region" {}
variable "sns_topic_arn" {}
variable "alarm_name" {}

variable "publish_sns_lambda_name" {
  description = "name of the check alarm status lambda function"
  default = "publish-sns"
}

variable "periodic_schedule_expression" {
  default = "rate(15 minutes)"
}