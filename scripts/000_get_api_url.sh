#!/bin/bash

source ../terraform/shared/get-profile.sh

API_ID=$(aws apigateway get-rest-apis --region us-east-1 --profile "${PROFILE}" | \
jq -r '.items[] | select(.name == "LocalStack API Test") | .id')

if [ -z "$API_ID" ]; then
  echo "ERROR: API ID not found."
  exit
fi

if [[ "${PROFILE}" == "local" ]]; then
  export API_URL="http://localhost:4566/restapis/${API_ID}/local/_user_request_"
else
  export API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/local-test"
fi
echo "API_URL: ${API_URL}"
