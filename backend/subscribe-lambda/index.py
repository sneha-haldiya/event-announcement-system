import json
import boto3
import os

sns = boto3.client('sns')
TOPIC_ARN = os.environ['TOPIC_ARN']

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        email = body.get('email')

        # Basic Gmail check
        if not email or "@gmail.com" not in email:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Only Gmail addresses are allowed."})
            }

        sns.subscribe(
            TopicArn=TOPIC_ARN,
            Protocol='email',
            Endpoint=email
        )

        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Subscription request sent! Please confirm in your inbox."})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
