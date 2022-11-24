#!/bin/bash

source ../terraform/shared/get-profile.sh

echo "Invoking LambdaRequestHandler."

test -f response.json && rm response.json

start=$(date +%s)

aws lambda invoke --function-name LambdaRequestHandler \
  --region us-east-1 \
  --profile "${PROFILE}" \
  --payload file://invoke-lambda-payload.json \
  response.json

test -f response.json && echo "$(<response.json)" | jq

end=$(date +%s)

echo "Execution time was $((end-start)) seconds."
