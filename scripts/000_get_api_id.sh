#!/bin/bash

API_ID=`awslocal apigateway get-rest-apis | jq -r '.items[] | .id'`
echo "API_ID: ${API_ID}"
API_URL="http://localhost:4566/restapis/${API_ID}/local/_user_request_"
