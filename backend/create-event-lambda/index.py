import json
import boto3
import os
import traceback

s3 = boto3.client('s3')
sns = boto3.client('sns')

BUCKET = os.environ['BUCKET_NAME']
TOPIC_ARN = os.environ['TOPIC_ARN']
FILE_NAME = 'events.json'

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])

        # Load existing events
        try:
            data = s3.get_object(Bucket=BUCKET, Key=FILE_NAME)
            try:
                raw_data = data['Body'].read()
                events = json.loads(raw_data) if raw_data.strip() else []
            except s3.exceptions.NoSuchKey:
                events = []
            except json.JSONDecodeError:
                events = []

        except s3.exceptions.NoSuchKey:
            events = []

        # Append new event
        events.append(body)

        # Upload events back to S3
        s3.put_object(Bucket=BUCKET, Key=FILE_NAME, Body=json.dumps(events))

        # Notify subscribers
        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject="📣 New Event Announcement",
            Message=json.dumps(body, indent=2)
        )

        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST",
                "Access-Control-Allow-Headers": "*"
            },
            "body": json.dumps({"message": "Event created and notification sent!"})
        }

    except Exception as e:
        print("ERROR:", traceback.format_exc())
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST",
                "Access-Control-Allow-Headers": "*"
            },
            "body": json.dumps({
                "error": str(e),
                "trace": traceback.format_exc()
            })
        }
