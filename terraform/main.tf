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

resource "aws_apigatewayv2_api" "http_api" {
  name          = "event-announcement-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_lambda_permission" "subscribe_api_permission" {
  statement_id  = "AllowAPIGatewayInvokeSubscribe"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.subscribe_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "create_event_api_permission" {
  statement_id  = "AllowAPIGatewayInvokeCreateEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_event_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "subscribe_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.subscribe_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "create_event_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.create_event_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "subscribe_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /subscribe"
  target    = "integrations/${aws_apigatewayv2_integration.subscribe_integration.id}"
}

resource "aws_apigatewayv2_route" "create_event_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /create-event"
  target    = "integrations/${aws_apigatewayv2_integration.create_event_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

output "api_base_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}