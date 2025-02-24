variable "mon_conf" {
  description = "update the value inside terraform.tfvars file"
  type = any
}

variable "email_endpoints" {
  type = list(string)
  description = "email endpoints where alarm notifications are sent"
}

variable "phone_numbers" {
  type = list(string)
  description = "Phone numbers where alarm notifications are sent. Note that additional AWS service is required for sending notifications."
}

variable "app_urls" {
  type = list(string)
  description = "Application URLs to be monitored. "
}

locals {
  prefix = "${var.mon_conf.tags.application}-${var.mon_conf.env}"
  prefix_noenv = var.mon_conf.tags.application

  tags = merge(var.mon_conf.tags, { "env" : var.mon_conf.env })
}

