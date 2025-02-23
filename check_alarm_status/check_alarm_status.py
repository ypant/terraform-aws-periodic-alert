import boto3
import time
import os, sys
import logging
import datetime

#SNS_EVT_SRC="aws:sns"
ALARM_OK = "OK"
ALARM = "ALARM"
#ERROR_MSG_SUBJECT="Warning...The endpoint is still down"
#ERROR_MSG=" Please check the alarm raised earlier, the endpoint is till down!"

def lambda_handler(event, context):
  region             = os.environ['region']
  sns_topic_arn      = os.environ['sns_topic_arn']
  alarm_name         = os.environ['alarm_name']
  periodic_rule_name = os.environ['periodic_rule_name']

  print (event)

  state = check_alarm_status(alarm_name)

  print(f"alarm state {state}")

  client = boto3.client('events')

  if state == ALARM_OK:
    print("Disabling the periodic rule")
    client.disable_rule(Name=periodic_rule_name)
    #print(f"The alarm '{alarm_name}' is in '{state}' state.")
  elif state == ALARM:
    print("Enabling the periodic rule")
    client.enable_rule(Name=periodic_rule_name)

def check_alarm_status(alarm_name):
  # Create a CloudWatch client
  cloudwatch_client = boto3.client('cloudwatch')

  # Retrieve the alarm state
  response = cloudwatch_client.describe_alarms(
    AlarmNames=[alarm_name]
  )

  # Extract the alarm state
  if response['MetricAlarms']:
    alarm_state = response['MetricAlarms'][0]['StateValue']
    return alarm_state
  else:
    return None

