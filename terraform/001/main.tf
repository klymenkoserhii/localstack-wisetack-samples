provider "aws" {
  profile = var.profile

  region  = "us-west-2"
  alias  = "us-west-2"

  default_tags {
    tags = {
      Environment = "local"
      Service     = "LocalStack"
    }
  }

  s3_use_path_style           = var.use_localstack
  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack

  endpoints {
    acm             = var.use_localstack ? "http://localhost:4566" : null
    apigateway      = var.use_localstack ? "http://localhost:4566" : null
    cloudformation  = var.use_localstack ? "http://localhost:4566" : null
    cloudwatch      = var.use_localstack ? "http://localhost:4566" : null
    cloudwatchevents = var.use_localstack ? "http://localhost:4566" : null
    cloudwatchlogs  = var.use_localstack ? "http://localhost:4566" : null
    cognitoidentity = var.use_localstack ? "http://localhost:4566" : null
    cognitoidp      = var.use_localstack ? "http://localhost:4566" : null
    cognitosync     = var.use_localstack ? "http://localhost:4566" : null
    dynamodb        = var.use_localstack ? "http://localhost:4566" : null
    es              = var.use_localstack ? "http://localhost:4566" : null
    iam             = var.use_localstack ? "http://localhost:4566" : null
    kinesis         = var.use_localstack ? "http://localhost:4566" : null
    lambda          = var.use_localstack ? "http://localhost:4566" : null
    route53         = var.use_localstack ? "http://localhost:4566" : null
    redshift        = var.use_localstack ? "http://localhost:4566" : null
    s3              = var.use_localstack ? "http://s3.localhost.localstack.cloud:4566" : null
    secretsmanager  = var.use_localstack ? "http://localhost:4566" : null
    ses             = var.use_localstack ? "http://localhost:4566" : null
    sns             = var.use_localstack ? "http://localhost:4566" : null
    sqs             = var.use_localstack ? "http://localhost:4566" : null
    ssm             = var.use_localstack ? "http://localhost:4566" : null
    stepfunctions   = var.use_localstack ? "http://localhost:4566" : null
    sts             = var.use_localstack ? "http://localhost:4566" : null
  }
}

resource "aws_dynamodb_table" "us-east-1-local-test" {
  provider = aws.us-east-1

  hash_key         = "myAttribute"
  name             = "myTable"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  read_capacity    = 1
  write_capacity   = 1

  attribute {
    name = "myAttribute"
    type = "S"
  }
}

resource "aws_dynamodb_table" "us-west-2-local-test" {
  provider = aws.us-west-2

  hash_key         = "myAttribute"
  name             = "myTable"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  read_capacity    = 1
  write_capacity   = 1

  attribute {
    name = "myAttribute"
    type = "S"
  }
}

resource "aws_dynamodb_global_table" "global-table-local-test" {
  depends_on = [
    aws_dynamodb_table.us-east-1-local-test,
    aws_dynamodb_table.us-west-2-local-test
  ]
  provider = aws.us-east-1

  name = "global-table-local-test"
  replica {
    region_name = "us-east-1"
  }
  replica {
    region_name = "us-west-2"
  }
}

