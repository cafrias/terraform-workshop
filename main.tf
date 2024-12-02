terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.2.0"
    }
  }
}

provider "aws" {
  region = var.region
  profile = var.profile
}

#
# Data
#
data "aws_caller_identity" "user" {}

#
# Locals
#
locals {
  account_id = data.aws_caller_identity.user.account_id
}

#
# API Gateway
#
resource "aws_api_gateway_rest_api" "api" {
  name = "Terraform Workshop"
}

resource "aws_api_gateway_resource" "hello" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "hello"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "get_hello" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "hello" {
  http_method = aws_api_gateway_method.get_hello.http_method
  resource_id = aws_api_gateway_resource.hello.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri = aws_lambda_function.hello.invoke_arn
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.hello.id,
      aws_api_gateway_method.get_hello.id,
      aws_api_gateway_integration.hello.id,
    ])),
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment
}

output "api_gateway_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/${var.environment}"
}

#
# Lambda
#
locals {
  hello_lambda_name = "terraform-workshop-hello"
}

resource "aws_lambda_function" "hello" {
  function_name = local.hello_lambda_name
  role = aws_iam_role.lambda_assume_role.arn
  handler = "index.handler"
  runtime = "nodejs20.x"
  filename = var.hello_package
  source_code_hash = filebase64sha256(var.hello_package)

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.hello,
  ]
}

resource "aws_lambda_permission" "hello" {
  statement_id = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.get_hello.http_method}${aws_api_gateway_resource.hello.path}"
}

#
# Lambda + Cloudwatch
#
resource "aws_cloudwatch_log_group" "hello" {
  name = "/aws/lambda/${local.hello_lambda_name}"
  retention_in_days = 7
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name   = "lambda_logging"
  path = "/"
  policy = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = aws_iam_role.lambda_assume_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

#
# IAM
#
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_assume_role" {
  name = "terraform-workshop-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
