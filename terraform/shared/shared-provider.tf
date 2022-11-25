terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.32"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
  }
  required_version = "~> 1.3"
}

provider "aws" {
  profile = var.profile
  region  = "us-east-1"
  alias  = "us-east-1"


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