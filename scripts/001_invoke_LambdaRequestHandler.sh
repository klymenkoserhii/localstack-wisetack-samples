#!/bin/bash

echo "Invoking LambdaRequestHandler."

test -f response.json && rm response.json

start=$(date +%s)

awslocal lambda invoke --function-name LambdaRequestHandler \
  --payload file://invoke-payload.json \
  response.json

test -f response.json && echo $(<response.json) | jq

end=$(date +%s)

echo "Execution time was $(expr $end - $start) seconds."
