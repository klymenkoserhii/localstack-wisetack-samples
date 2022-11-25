# Description

This repository demonstrates some discrepancies between AWS and LocalStack.

## Prerequisites

* Docker
* Docker compose
* `awslocal` CLI
* Terraform
* Java 11
* Maven

Before reproducing issues please build test lambda and start LocalStack by running 
following commands in project's root directory:

```shell
mvn clean install
docker-compose up
```

### 1. AWS Global Table Creation with Terraform Issue.

Steps to reproduce:

```shell
cd ./terraform/001
./init.sh
./apply.sh
```

Global table creation fails with error:

```shell
╷
│ Error: Request cancelled
│
│   with aws_dynamodb_global_table.global-table-local-test,
│   on main.tf line 79, in resource "aws_dynamodb_global_table" "global-table-local-test":
│   79: resource "aws_dynamodb_global_table" "global-table-local-test" {
│
│ The plugin.(*GRPCProvider).ApplyResourceChange request was cancelled.
╵

Stack trace from the terraform-provider-aws_v4.32.0_x5 plugin:

panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x2 addr=0x0 pc=0x10af8cd7c]

goroutine 486 [running]:
github.com/hashicorp/terraform-provider-aws/internal/service/dynamodb.resourceGlobalTableStateRefreshFunc.func1()
	github.com/hashicorp/terraform-provider-aws/internal/service/dynamodb/global_table.go:237 +0x1ac
github.com/hashicorp/terraform-plugin-sdk/v2/helper/resource.(*StateChangeConf).WaitForStateContext.func1()
	github.com/hashicorp/terraform-plugin-sdk/v2@v2.22.0/helper/resource/state.go:110 +0x174
created by github.com/hashicorp/terraform-plugin-sdk/v2/helper/resource.(*StateChangeConf).WaitForStateContext
	github.com/hashicorp/terraform-plugin-sdk/v2@v2.22.0/helper/resource/state.go:83 +0x1a8

Error: The terraform-provider-aws_v4.32.0_x5 plugin crashed!
```

Upon AWS cloud, this script runs without error. It looks like LocalStack don't return all data 
required for terraform provider.  

### 2. API Gateway Lambda Integration Related Discrepancies.

The two possible integrations are 'Lambda-Proxy' and 'Lambda'. 

In this sample 'Lambda' integration used. This type of the integration offers more control 
over transmission data. The request can be modified before it is sent to lambda and the 
response can be modified after it is sent from lambda. This can be done by mapping templates 
which transforms the payload, as per the user customisations. API Gateway uses Velocity
Template Language (VTL) engine to process body mapping templates for the integration request
and integration response. The settings can be easily exported as Swagger specification.

Unfortunately, mapping templates created to work with AWS cloud do not work with LocalStack.

#### 2.1 Request Mapping Template Discrepancies.

- $util.escapeJavaScript($path.get($paramName)) function works differently - LocalStack version 
  returns string surrounded by double quotes, while AWS version - without double quotes.
- $allParams.get('header') LocalStack version returns data in different format (array of tuples)
  than AWS version (dictionary).

These discrepancies require to keep two versions of mapping templates, one for AWS 
and another for LocalStack.

You can find request mapping templates source code here:
- [AWS version](./terraform/002/request-template-aws.vm)
- [LocalStack version](./terraform/002/request-template-local.vm)

#### 2.2 Response Mapping Template Issues.

#### 2.3 Mapping status codes to static values not working.

Please see documentation on this feature [here](https://aws.amazon.com/premiumsupport/knowledge-center/api-gateway-status-codes-rest-api/)

 