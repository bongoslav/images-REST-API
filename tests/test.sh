#!/bin/bash

# base url
BASE_URL="http://localhost:3000"

# params
MIN_LAT=50
MAX_LAT=52
MIN_LONG=-5
MAX_LONG=5

###### post endpoint ######
POST_ENDPOINT="/upload"
IMAGE_PATH="test-image-1.jpeg"

RESPONSE=$(curl -X POST -s -w "\nTime taken: %{time_total}s\nHTTP Status: %{http_code}\n" -F "image=@$IMAGE_PATH" "${BASE_URL}${POST_ENDPOINT}")
HTTP_STATUS=$(echo "$RESPONSE" | awk '/HTTP Status:/ {print $3}')
RESPONSE_TIME=$(echo "$RESPONSE" | awk '/Time taken:/ {print $3}')
# HTTP_STATUS=$(echo "$RESPONSE" | awk '/HTTP Status/ {print $3}')
# RESPONSE_TIME=$(echo "$RESPONSE" | awk -F ': ' '/Time taken/ {print $2}')

if [[ "$HTTP_STATUS" =~ ^2[0-9]{2}$ ]]; then
  echo -n "✅ "
else
  echo -n "❌ "
fi
echo "POST Endpoint: ${POST_ENDPOINT}"
echo "response: ${RESPONSE}"
echo "----------------"

## upload the second photo with different coordinates to test the GET
echo "Uploading a second image with different coords for testing."
IMAGE_PATH_2="test-image-2.jpeg"
curl -X POST -F "image=@$IMAGE_PATH_2" "${BASE_URL}${POST_ENDPOINT}"
echo
echo "----------------"

###### get endpoints ######
GET_ENDPOINTS=(
  "/images/?minLat=$MIN_LAT&maxLat=$MAX_LAT&minLong=$MIN_LONG&maxLong=$MAX_LONG"
  "/images/1"
  "/all-images-info"
)

for endpoint in "${GET_ENDPOINTS[@]}"; do
  RESPONSE=$(curl -s -w "\nTime taken: %{time_total}s\nHTTP Status: %{http_code}\n" "${BASE_URL}${endpoint}")
  HTTP_STATUS=$(echo "$RESPONSE" | awk '/HTTP Status:/ {print $3}')
  RESPONSE_TIME=$(echo "$RESPONSE" | awk '/Time taken:/ {print $3}')

  if [[ "$HTTP_STATUS" =~ ^2[0-9]{2}$ ]]; then
    echo -n "✅ "
  else
    echo -n "❌ "
  fi
  echo "GET Endpoint: ${endpoint}"
  echo "response: ${RESPONSE}"
  echo "----------------"
done

### GET endpoint; check if an image is returned ###
thumbnail_endpoint="/images/1/thumbnail"
RESPONSE=$(curl -I -s -w "\nTime taken: %{time_total}s\nHTTP Status: %{http_code}\n" "${BASE_URL}${thumbnail_endpoint}")
HTTP_STATUS=$(echo "$RESPONSE" | awk '/HTTP Status:/ {print $3}')
RESPONSE_TIME=$(echo "$RESPONSE" | awk '/Time taken:/ {print $3}')
CONTENT_TYPE=$(echo "$RESPONSE" | grep "Content-Type:" | awk '{print $2}')

if [[ "$HTTP_STATUS" =~ ^2[0-9]{2}$ ]]; then
  echo -n "✅ "
else
  echo -n "❌ "
fi
echo "GET Endpoint: ${thumbnail_endpoint}"
echo "content type:  ${CONTENT_TYPE}"
echo "Time taken:    ${RESPONSE_TIME} s"
echo "HTTP Status:   ${HTTP_STATUS}"
echo "----------------"

###### delete endpoint ######
DELETE_ENDPOINT="/images/1"

RESPONSE=$(curl -X DELETE -s -w "\nTime taken: %{time_total}s\nHTTP Status: %{http_code}\n" "${BASE_URL}${DELETE_ENDPOINT}")
HTTP_STATUS=$(echo "$RESPONSE" | awk '/HTTP Status:/ {print $3}')
RESPONSE_TIME=$(echo "$RESPONSE" | awk '/Time taken:/ {print $3}')

if [[ "$HTTP_STATUS" =~ ^2[0-9]{2}$ ]]; then
  echo -n "✅ "
else
  echo -n "❌ "
fi
echo "DELETE Endpoint: ${DELETE_ENDPOINT}"
echo "response: ${RESPONSE}"
echo "----------------"

# add optimisation...
