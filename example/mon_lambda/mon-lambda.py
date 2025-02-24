import json
import requests
#import httplib
import errno
import socket
import boto3
import os
import logging
import random

logger = logging.getLogger()
logging.getLogger("boto3").setLevel(logging.WARNING)
logging.getLogger("botocore").setLevel(logging.WARNING)

#ERROR_MSG_SUBJECT="Warning...Website is down"
#ERROR_MSG=" Website is down "

def lambda_handler(event, context):
  debug_level       = os.environ['debug_level']
  logger.setLevel( debug_level)  # "INFO") # DEBUG

  sns_topic_arn     = os.environ['sns_topic_arn']
  metric_name       = os.environ['metric_name']
  metric_namespace  = os.environ['metric_namespace']
  metric_dim_name   = os.environ['metric_dim_name']
  app_urls           = json.loads(os.environ['app_urls'])

  for app_url in app_urls:
    try: 
      with requests.Session() as c:
        resp = c.get(app_url)
        put_custom_metric( metric_namespace, metric_name, metric_dim_name, 
          app_url, resp.status_code )   
        
        print("posted metrics successfully....")
        teams_color = "00FF00"  # Green
    except requests.exceptions.RequestException as e:  
      print(e)       
      put_custom_metric( metric_namespace, metric_name, metric_dim_name, 
        app_url, 1000 ) # response.status_code, just input http status code   

def put_custom_metric( metric_namespace, metric_name, metric_dim_name, url, val ):
  cloudwatch = boto3.client('cloudwatch')

  resp = cloudwatch.put_metric_data(
      Namespace=metric_namespace,
      MetricData=[
        {
          'MetricName': metric_name,
          'Dimensions': [
            {
              'Name': metric_dim_name,
              'Value': url,
            },
          ],
          'Value': val,
          'Unit': 'None' # 'Count'
        },
      ]
  )

  print(resp)