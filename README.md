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

When I use [request mapping template](./terraform/002/request-template-aws.vm) (which is working for AWS) in LocalStack I have this error:

```shell
localstack_wisetack_samples  | 2022-11-26T10:22:01.614 ERROR --- [   asgi_gw_2] l.s.apigateway.invocations : Error invoking integration for API Gateway ID 'lj2gaa9hdn': An error occurred (UnsupportedMediaTypeException) when calling the Invoke operation: The payload is not JSON: {    "apiContext": {        "apiId": "lj2gaa9hdn",        "method": "POST",        "sourceIp": "172.18.0.1",        "userAgent": "unirest-java/curl",        "path": "/local/products/abcd-1234/items",        "protocol": "HTTP/1.1",        "requestId": "08f4ff6d-51df-45eb-83fd-3a3fbf132401",        "stage": "local"    },    "path": {        "parameterMap": {                        "productId": ""abcd-1234""                    }    },    "querystring": {        "parameterMap":{                        "status": ""PENDING"",                        "limit": "100"                    }    },    "header": {        "parameterMap": {                    }    },    "body": {"prop": "value"}}
localstack_wisetack_samples  | Traceback (most recent call last):
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/services/apigateway/invocations.py", line 291, in invoke_rest_api_integration
localstack_wisetack_samples  |     response = invoke_rest_api_integration_backend(invocation_context)
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/services/apigateway/invocations.py", line 333, in invoke_rest_api_integration_backend
localstack_wisetack_samples  |     return LambdaIntegration().invoke(invocation_context)
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/services/apigateway/integration.py", line 343, in invoke
localstack_wisetack_samples  |     result = call_lambda(
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/services/apigateway/integration.py", line 106, in call_lambda
localstack_wisetack_samples  |     inv_result = lambda_client.invoke(
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/botocore/client.py", line 514, in _api_call
localstack_wisetack_samples  |     return self._make_api_call(operation_name, kwargs)
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/botocore/client.py", line 938, in _make_api_call
localstack_wisetack_samples  |     raise error_class(parsed_response, operation_name)
localstack_wisetack_samples  | botocore.errorfactory.UnsupportedMediaTypeException: An error occurred (UnsupportedMediaTypeException) when calling the Invoke operation: The payload is not JSON: {    "apiContext": {        "apiId": "lj2gaa9hdn",        "method": "POST",        "sourceIp": "172.18.0.1",        "userAgent": "unirest-java/curl",        "path": "/local/products/abcd-1234/items",        "protocol": "HTTP/1.1",        "requestId": "08f4ff6d-51df-45eb-83fd-3a3fbf132401",        "stage": "local"    },    "path": {        "parameterMap": {                        "productId": ""abcd-1234""                    }    },    "querystring": {        "parameterMap":{                        "status": ""PENDING"",                        "limit": "100"                    }    },    "header": {        "parameterMap": {                    }    },    "body": {"prop": "value"}}
localstack_wisetack_samples  | 2022-11-26T10:22:01.617  INFO --- [   asgi_gw_2] localstack.request.http    : POST /restapis/lj2gaa9hdn/local/_user_request_/products/abcd-1234/items => 400
```

Digging further I found following **discrepancies:**

- **$util.escapeJavaScript($path.get($paramName))** 
  
  LocalStack version 
  returns string surrounded by double quotes, while AWS version - without double quotes.
- **$input.params().get('header')** 

  LocalStack version returns data in different format - generate array of (key, value) tuples, while
  AWS version returns dictionary.

These discrepancies require to keep two versions of mapping templates, one for AWS 
and another for LocalStack.

You can find request mapping templates source code here:
- [AWS version](./terraform/002/request-template-aws.vm)
- [LocalStack version](./terraform/002/request-template-local.vm)

**Workarounds for differences**:
<table>
<tr>
<td>AWS</td>
<td>LocalStack</td>
</tr>
<tr>
<td>

```vtl
"$util.escapeJavaScript($path.get($paramName))"
```
</td>
<td>

```vtl
$util.escapeJavaScript($path.get($paramName))
```
</td>
</tr>
<tr>
<td>

```vtl
#set($allParams = $input.params())
#set($header = $allParams.get('header'))

#foreach($paramName in $header.keySet())
"$paramName": "$util.escapeJavaScript($header.get($paramName))"#if($foreach.hasNext),#end
#end
```
</td>
<td>

```vtl
#set($allParams = $input.params())
#set($header = $allParams.get('header'))

#foreach($i in [0..16])#set($item = $header[$i])
#if($item[0])#if($i > 0),#end
"$item[0]": $util.escapeJavaScript($item[1])
#end
#end
```
</td>
</tr>
</table>

#### 2.2 Response Mapping Template Issues.

#### 2.3 Mapping status codes to static values not working.

Please see documentation on this feature [here](https://aws.amazon.com/premiumsupport/knowledge-center/api-gateway-status-codes-rest-api/)

 