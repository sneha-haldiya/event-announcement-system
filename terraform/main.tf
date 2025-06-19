provider "aws" {
  region = "ap-south-1"
}

resource "aws_sns_topic" "event_topic" {
  name = "event-announcement-topic"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sns_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

output "sns_topic_arn" {
  value = aws_sns_topic.event_topic.arn
}

data "archive_file" "subscribe_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/subscribe-lambda/index.py"
  output_path = "${path.module}/subscribe_lambda.zip"
}

resource "aws_lambda_function" "subscribe_lambda" {
  function_name = "subscribeLambda"
  filename      = data.archive_file.subscribe_lambda_zip.output_path
  source_code_hash = data.archive_file.subscribe_lambda_zip.output_base64sha256
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.event_topic.arn
    }
  }
}

data "archive_file" "create_event_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/create-event-lambda/index.py"
  output_path = "${path.module}/create_event_lambda.zip"
}

resource "aws_lambda_function" "create_event_lambda" {
  function_name = "createEventLambda"
  filename      = data.archive_file.create_event_lambda_zip.output_path
  source_code_hash = data.archive_file.create_event_lambda_zip.output_base64sha256
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      BUCKET_NAME = "event-announcement-nsj-frontend-2025"
      TOPIC_ARN   = aws_sns_topic.event_topic.arn
    }
  }
}
