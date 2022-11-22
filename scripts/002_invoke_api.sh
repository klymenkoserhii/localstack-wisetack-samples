#!/bin/bash

set -e


source ./000_get_api_id.sh
start=`date +%s`

data=`curl -v -H "Content-Type: application/json" -H "User-Agent: unirest-java/curl" \
-d "{\"test\": \"test\"}" -X POST ${API_URL}/merchants/abcd-1234/transactions`

echo ${data} | jq

end=`date +%s`
echo "Execution time was `expr $end - $start` seconds."
