resource "aws_lambda_function" "lambda-function-LambdaRequestHandler" {
  filename = "../../target/localstack-wisetack-samples-1.0.jar"
  function_name = "LambdaRequestHandler"
  runtime = "java11"
  role = aws_iam_role.lambda-role.arn
  timeout = "900"
  source_code_hash = filebase64sha256("../../target/localstack-wisetack-samples-1.0.jar")
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
  body = templatefile("./api.json", {
    api-role-arn = aws_iam_role.api-role.arn
    lambda-arn-LambdaRequestHandler = aws_lambda_function.lambda-function-LambdaRequestHandler.invoke_arn
    request-template = file("./request-template.vm")
  })
}

