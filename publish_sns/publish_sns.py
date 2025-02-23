import boto3
import time
import os, sys
import logging
import datetime

#SNS_EVT_SRC="aws:sns"
ALARM_OK = "OK"
ALARM = "ALARM"
ERROR_MSG_SUBJECT="Warning...Website is still down"
ERROR_MSG="Please check the alarm raised earlier, the endpoint is still down!"

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
    print(f"Disabling rule")
    client.disable_rule(Name=periodic_rule_name)
    #print(f"The alarm '{alarm_name}' is in '{state}' state.")
  elif state == ALARM:
    print(f"Publishing an event ...Still in '{state}' state.")
    client.enable_rule(Name=periodic_rule_name)
    sns_client = boto3.client('sns')    
    sns_client.publish( TopicArn = sns_topic_arn, Subject = ERROR_MSG_SUBJECT, Message = ERROR_MSG )
  else:
    print(f"Alarm '{alarm_name}' not found.")


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
