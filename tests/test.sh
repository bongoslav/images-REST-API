#!/bin/bash

# base url
BASE_URL="http://localhost:3000"

# params
MIN_LAT=50
MAX_LAT=60
MIN_LONG=-5
MAX_LONG=10

###### post endpoint ######
POST_ENDPOINT="/upload"

IMAGE_PATH="test-image-1.jpeg"

RESPONSE=$(curl -X POST -s -w "\nTime taken: %{time_total}s\nHTTP Status: %{http_code}\n" -F "image=@$IMAGE_PATH" "${BASE_URL}${POST_ENDPOINT}")
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP Status" | awk '{print $3}')
RESPONSE_TIME=$(echo "$RESPONSE" | grep -oP 'Time taken: \K[0-9.]+')
echo "POST Endpoint: ${POST_ENDPOINT}"

if [ "$HTTP_STATUS" -eq 201 ]; then
  printf -- "- response code:\t%s successful response ✅\n" "${HTTP_STATUS}"
else
  echo "Upload failed with $HTTP_STATUS ❌"
fi

printf -- "- response time:%.6f s\n" "${RESPONSE_TIME}"
echo "----------------"

###### get endpoints ######
GET_ENDPOINTS=(
  "/images/?minLat=$MIN_LAT&maxLat=$MAX_LAT&minLong=$MIN_LONG&maxLong=$MAX_LONG"
  "/images/1"
  "/images/1/thumbnail"
  "/all-images-info"
)

for endpoint in "${GET_ENDPOINTS[@]}"; do
  RESPONSE=$(curl -o /dev/null -s -w 'HTTP_STATUS:%{http_code}\nRESPONSE_TIME:%{time_total}\nRESPONSE:%{response_code}\n' "${BASE_URL}${endpoint}")
  HTTP_STATUS=$(echo "$RESPONSE" | awk -F 'HTTP_STATUS:' '{print $2}')
  RESPONSE_TIME=$(echo "$RESPONSE" | awk -F 'RESPONSE_TIME:' '{print $2}' | tr -d '\n')

  RESPONSE_DATA=$(echo "$RESPONSE" | awk -F 'RESPONSE:' '{print $2}')

  echo "GET Endpoint: ${endpoint}"

  if [[ "$HTTP_STATUS" =~ 200 ]]; then
    printf -- "- response code:\t%s successful response ✅\n" "${HTTP_STATUS}"
  else
    echo "Upload failed with $HTTP_STATUS ❌"
  fi

  printf -- "- response time:%.6f s\n" "${RESPONSE_TIME}"
  echo "----------------"
done

###### delete endpoint ######
DELETE_ENDPOINT="/images/1"

RESPONSE=$(curl -X DELETE -s -w "\nTime taken: %{time_total}s\nHTTP Status: %{http_code}\n" "${BASE_URL}${DELETE_ENDPOINT}")
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP Status" | awk '{print $3}')
RESPONSE_TIME=$(echo "$RESPONSE" | grep -oP 'Time taken: \K[0-9.]+')
echo "DELETE Endpoint: ${DELETE_ENDPOINT}"

if [ "$HTTP_STATUS" -eq 200 ]; then
  printf -- "- response code:\t%s successful response ✅\n" "${HTTP_STATUS}"
else
  echo "Upload failed with $HTTP_STATUS ❌"
fi

printf -- "- response time:%.6f s\n" "${RESPONSE_TIME}"
echo "----------------"

