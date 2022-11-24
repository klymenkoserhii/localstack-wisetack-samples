locals {
  stage-name = "local-test"
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

resource "aws_lambda_function" "lambda-test-function-LambdaRequestHandler" {
  filename = "../../target/localstack-wisetack-samples-1.0.jar"
  function_name = "LambdaRequestHandler"
  runtime = "java11"
  role = aws_iam_role.lambda-test-role.arn
  timeout = "900"
  source_code_hash = filebase64sha256("../../target/localstack-wisetack-samples-1.0.jar")
  publish = true
  handler = "com.wisetack.samples.LambdaRequestHandler::handleRequest"
  architectures = ["arm64"]
}

resource "aws_iam_role" "lambda-test-role" {
  name = "lambdaTestRole"
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

resource "aws_iam_role" "api-test-role" {
  name               = "api-test-role"
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

resource "aws_iam_role_policy" "api-test-policy" {
  name     = "api-test-policy"
  role     = aws_iam_role.api-test-role.id
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

resource "aws_api_gateway_rest_api" "api-test" {
  name = "LocalStack API Test"
  body = templatefile("./api.json", {
    api-role-arn = aws_iam_role.api-test-role.arn
    lambda-arn-LambdaRequestHandler = aws_lambda_function.lambda-test-function-LambdaRequestHandler.invoke_arn
    request-template = replace(replace(file(var.use_localstack ? "./request-template-localstack.vm" : "./request-template-aws.vm"), "\n", ""), "\"", "\\\"")
    response-template = replace(replace(file(var.use_localstack ? "./response-template-localstack.vm" : "./response-template-aws.vm"), "\n", ""), "\"", "\\\"")
  })
}

resource "aws_api_gateway_deployment" "api-test-deployment" {
  rest_api_id = aws_api_gateway_rest_api.api-test.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api-test.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "api-test-access-logs" {
  name              = "/local-test/apigateway/api"
  retention_in_days = 365
}

resource "aws_api_gateway_stage" "api-test-stage" {
  deployment_id = aws_api_gateway_deployment.api-test-deployment.id
  rest_api_id = aws_api_gateway_rest_api.api-test.id
  stage_name = local.stage-name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api-test-access-logs.arn
    format = local.api_gateway_log_format
  }
}


