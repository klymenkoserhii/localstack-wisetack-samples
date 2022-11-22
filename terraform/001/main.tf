data "aws_caller_identity" "current-identity" {}

locals {
  alias_name = "LIVE"
  lambda-arn-prefix = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${data.aws_caller_identity.current-identity.account_id}:function:"
  stage-name = "local"
  api_gateway_log_format = jsonencode({
    "requestId":          "$context.requestId",
    "trueRequestId":      "$context.extendedRequestId",
    "sourceIp":           "$context.identity.sourceIp",
    "requestTime":        "$context.requestTime",
    "httpMethod":         "$context.httpMethod",
    "resourcePath":       "$context.resourcePath",
    "status":             "$context.status",
    "protocol":           "$context.protocol",
    "responseLength":     "$context.responseLength",
    "responseLatency":    "$context.responseLatency",
    "integrationLatency": "$context.integration.latency",
    "validationError":    "$context.error.validationErrorString",
    "userAgent":          "$context.identity.userAgent",
    "path":               "$context.path"
  })
}

resource "aws_lambda_function" "lambda-function-LambdaRequestHandler" {
  filename = "./target/localstack-wisetack-samples-1.0.jar"
  function_name = "LambdaRequestHandler"
  runtime = "java11"
  role = aws_iam_role.lambda-role.arn
  timeout = "900"
  source_code_hash = filebase64sha256("./target/localstack-wisetack-samples-1.0.jar")
  publish = true
  handler = "com.wisetack.samples.LambdaRequestHandler::handleRequest"
  architectures = ["arm64"]
}

resource "aws_iam_role" "lambda-role" {
  name = "lambdaRole"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_api_gateway_account" "api-account" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch-role.arn
}

resource "aws_iam_role" "cloudwatch-role" {
  name               = "cloudwatch-role"
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": ["apigateway.amazonaws.com", "sns.amazonaws.com", "sms.amazonaws.com"]
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  EOF
}

resource "aws_iam_role_policy" "cloudwatch-policy" {
  name     = "default"
  role     = aws_iam_role.cloudwatch-role.id
  policy   = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
            "logs:GetLogEvents",
            "logs:FilterLogEvents",
            "logs:PutMetricFilter",
            "logs:PutRetentionPolicy"
          ],
          "Resource": "*"
        }
      ]
    }
  EOF
}

resource "aws_iam_role" "api-role" {
  name               = "api-role"
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": "apigateway.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  EOF
}

resource "aws_iam_role_policy" "api-policy" {
  name     = "api-policy"
  role     = aws_iam_role.api-role.id
  policy   = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": "lambda:InvokeFunction",
          "Resource": "*"
        }
      ]
    }
  EOF
}

resource "aws_api_gateway_rest_api" "api" {
  name = "LocalStack Wisetack API"
  body = templatefile("./specs/api.json", {
    api-role-arn = aws_iam_role.api-role.arn
    lambda-arn-LambdaRequestHandler = aws_lambda_function.lambda-function-LambdaRequestHandler.invoke_arn
  })
}

resource "aws_api_gateway_deployment" "api-deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "api-access-logs" {
  name              = "/local-wisetack/apigateway/api"
  retention_in_days = 365
}

resource "aws_api_gateway_stage" "api-stage" {
  deployment_id = aws_api_gateway_deployment.api-deployment.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = local.stage-name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api-access-logs.arn
    format = local.api_gateway_log_format
  }
}

resource "aws_api_gateway_method_settings" "api-gateway-settings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = aws_api_gateway_stage.api-stage.stage_name
  method_path = "*/*"
  settings {
    metrics_enabled = true
    logging_level = "ERROR"
    # Limit the rate of calls to prevent abuse and unwanted charges
    throttling_rate_limit  = 100
    throttling_burst_limit = 50
  }
}

resource "aws_api_gateway_gateway_response" "gateway-bad-request-body-response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  response_type = "BAD_REQUEST_BODY"
  status_code   = "400"
  response_templates = {
    "application/json" = "{\"message\":\"$context.error.validationErrorString\",\"code\":\"$context.error.responseType\",\"requestId\":\"$context.requestId\"}"
  }
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'"
  }
}





