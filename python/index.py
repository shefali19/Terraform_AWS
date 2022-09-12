import uuid
import boto3
import urllib
import json
import os

s3 = boto3.client("s3")
client = boto3.client('stepfunctions', region_name = 'eu-central-1')

def lambda_handler(event, context):
    if event:
        print("Event : ", event)
        file_obj = event["Records"][0]
        global filename
        filename = urllib.parse.unquote_plus(str(file_obj['s3']['object']['key']))
        print("filename: ", filename)
        input_value = {'Filename': filename}
        response = client.start_execution(
            stateMachineArn='arn:aws:states:eu-central-1:000000000000:stateMachine:tf-worflow-engine',input = json.dumps(input_value)
        )
    return {
        "Filename":filename
    }