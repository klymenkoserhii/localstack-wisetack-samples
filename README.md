# Description

This repository demonstrates some discrepancies between AWS and LocalStack.

## Prerequisites

* Docker
* Docker compose
* `awslocal` CLI
* Terraform
* Java 11
* Maven
* [jq](https://stedolan.github.io/jq/)

Before reproducing issues:

- add local profile to ~/.aws/credentials like this:
  ```shell
  [local]
  aws_access_key_id=test
  aws_secret_access_key=test
  ```

- build test lambda and start LocalStack by running 
  following commands in the repository root directory:

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

### 2. API Gateway Lambda Integration Discrepancies.

The two possible API Gateway integrations for lambda are 'Lambda-Proxy' and 'Lambda'. 

In this sample 'Lambda' integration used. This type of the integration offers more control 
over transmission data. The request can be modified before it is sent to lambda and the 
response can be modified after it is sent from lambda. This can be done by mapping templates 
which transforms the payload, as per the user customisations. API Gateway uses Velocity
Template Language (VTL) engine to process body mapping templates for the integration request
and integration response. The settings can be easily exported as Swagger specification.

Unfortunately, mapping templates created to work with AWS Cloud do not work with LocalStack.

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

Digging further, I found the following **discrepancies:**

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

**Workarounds**:
<table>
<tr>
<td>AWS version</td>
<td>Workaround for LocalStack</td>
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
    "$paramName": "$util.escapeJavaScript($header.get($paramName))"
    #if($foreach.hasNext),#end
#end
```
</td>
<td>

```vtl
#set($allParams = $input.params())
#set($header = $allParams.get('header'))

#foreach($i in [0..16])#set($item = $header[$i])
    #if($item[0])
        #if($i > 0),#end
        "$item[0]": $util.escapeJavaScript($item[1])
    #end
#end
```
</td>
</tr>
</table>

#### 2.2 Response Mapping Template Issue - response headers and status codes override doesn't work.

When I use [response mapping template](./terraform/002/response-template-aws.vm) (which is working for AWS) in LocalStack I have this error:

```shell
localstack_wisetack_samples  | 2022-11-26T11:34:29.224 ERROR --- [   asgi_gw_2] l.s.apigateway.invocations : Error invoking integration for API Gateway ID '42x88rcuxw': line 1, column 268: expected assignment in set directive, got: ($context.responseOverride.header["$ ... ...
localstack_wisetack_samples  | Traceback (most recent call last):
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 332, in require_next_element
localstack_wisetack_samples  |     element = element_spec(self.filename, self._full_text,
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 270, in __init__
localstack_wisetack_samples  |     self.parse()
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 992, in parse
localstack_wisetack_samples  |     var_name, = self.identity_match(self.START)
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 287, in identity_match
localstack_wisetack_samples  |     raise NoMatch()
localstack_wisetack_samples  | airspeed.NoMatch
localstack_wisetack_samples  |
localstack_wisetack_samples  | During handling of the above exception, another exception occurred:
localstack_wisetack_samples  |
localstack_wisetack_samples  | Traceback (most recent call last):
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/services/apigateway/invocations.py", line 291, in invoke_rest_api_integration
localstack_wisetack_samples  |     response = invoke_rest_api_integration_backend(invocation_context)
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/services/apigateway/invocations.py", line 333, in invoke_rest_api_integration_backend
localstack_wisetack_samples  |     return LambdaIntegration().invoke(invocation_context)
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/services/apigateway/integration.py", line 375, in invoke
localstack_wisetack_samples  |     response_templates.render(invocation_context)
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/services/apigateway/templates.py", line 242, in render
localstack_wisetack_samples  |     response._content = self.render_vtl(template, variables=variables)
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/services/apigateway/templates.py", line 171, in render_vtl
localstack_wisetack_samples  |     return self.vtl.render_vtl(template, variables=variables)
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/utils/aws/templating.py", line 87, in render_vtl
localstack_wisetack_samples  |     rendered_template = t.merge(namespace)
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 95, in merge
localstack_wisetack_samples  |     self.merge_to(namespace, output, loader)
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 105, in merge_to
localstack_wisetack_samples  |     self.ensure_compiled()
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 100, in ensure_compiled
localstack_wisetack_samples  |     self.root_element = TemplateBody(self.filename, self.content)
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 270, in __init__
localstack_wisetack_samples  |     self.parse()
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 1245, in parse
localstack_wisetack_samples  |     self.block = self.next_element(Block)
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 314, in next_element
localstack_wisetack_samples  |     element = element_spec(self.filename, self._full_text, self.end)
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 270, in __init__
localstack_wisetack_samples  |     self.parse()
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/utils/aws/templating.py", line 162, in parse
localstack_wisetack_samples  |     self.next_element(
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 320, in next_element
localstack_wisetack_samples  |     element = element_class(self.filename, self._full_text,
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 270, in __init__
localstack_wisetack_samples  |     self.parse()
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 1208, in parse
localstack_wisetack_samples  |     self.block = self.next_element(Block)
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 314, in next_element
localstack_wisetack_samples  |     element = element_spec(self.filename, self._full_text, self.end)
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 270, in __init__
localstack_wisetack_samples  |     self.parse()
localstack_wisetack_samples  |   File "/opt/code/localstack/localstack/utils/aws/templating.py", line 162, in parse
localstack_wisetack_samples  |     self.next_element(
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 320, in next_element
localstack_wisetack_samples  |     element = element_class(self.filename, self._full_text,
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 270, in __init__
localstack_wisetack_samples  |     self.parse()
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 1186, in parse
localstack_wisetack_samples  |     self.assignment = self.require_next_element(Assignment, 'assignment')
localstack_wisetack_samples  |   File "/opt/code/localstack/.venv/lib/python3.10/site-packages/airspeed/__init__.py", line 335, in require_next_element
localstack_wisetack_samples  |     raise self.syntax_error(expected)
localstack_wisetack_samples  | airspeed.TemplateSyntaxError: line 1, column 268: expected assignment in set directive, got: ($context.responseOverride.header["$ ... ...
localstack_wisetack_samples  | 2022-11-26T11:34:29.226  INFO --- [   asgi_gw_2] localstack.request.http    : POST /restapis/42x88rcuxw/local/_user_request_/products/abcd-1234/items => 400
```

It looks like mapping template $context object does not contain responseOverride property which is used to override 
an API's response parameters and status codes. Please see [AWS documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-override-request-response-parameters.html) 
for more details. 

I have not found a workaround for this drawback.
I tried adding the responseOverride property to the $context object but that didn't work.

Also, it looks like **$util.parseJson()** mapping template function does not implemented in LocalStack.

You can find response mapping templates source code here:
- [Working AWS version](./terraform/002/response-template-aws.vm)
- [Not working localStack version](./terraform/002/response-template-local.vm)

At the moment it is not possible to override response headers and status codes when using API Gateway "Lambda" integration with LocalStack, 
but this is required in our project.

#### 2.3 Mapping status codes to static values doesn't work.

A status code can’t be passed directly from the Lambda function in a non-proxy integration. 
AWS recommends to use mapping templates or regular expressions to map the status codes.
Please see documentation on this feature [here](https://aws.amazon.com/premiumsupport/knowledge-center/api-gateway-status-codes-rest-api/)

In this sample I used following configuration to map 400 status code (file [api.json](./terraform/002/api.json) line 77):

```json
  ".*httpStatus\\\":400.*": {
    "statusCode": "400",
    "responseTemplates": {
      "application/json": "#set($errorMessage = $input.path('$.errorMessage'))\n $errorMessage"
    }
  }
```

This configuration works fine with AWS Cloud but does not work with LocalStack.

Steps to reproduce:

Deploy to LocalStack:
```shell
cd ./terraform/002
./init.sh
./apply.sh
```
Made post API call to generate 400 error:
```shell
cd ./scripts
./004_invoke_post_api_with_error.sh
```

In AWS Cloud 400 HTTP status code returned, but in LocalStack 200 returned.

You can find examples of API responses [here](./scripts/results/004).

> Note
> 
> Samples in this repo by default run against LocalStack, if you want to run them using AWS Cloud profile
> please update first line in the file [get-profile.sh](./terraform/shared/get-profile.sh) 


#### CONCLUSION

We cannot start to use LocalStack in our project until points 2.2 and 2.3 are fixed 
as we don't have workarounds for them.