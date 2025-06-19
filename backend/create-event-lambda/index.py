import json
import boto3
import os

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
            events = json.loads(data['Body'].read())
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
            "body": json.dumps({"message": "Event created and notification sent!"})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
