#!/bin/bash

##########################################################################################
# The plugin depends on infrastructure that cannot easily run on desktop operating systems
# We therefore run some basic infrastructure tests against a deployed reverse proxy
##########################################################################################

API_URL='http://localhost:3000'
WEB_ORIGIN='http://www.example.com'
ACCESS_TOKEN='1234567890'
RESPONSE_FILE=response.txt

#
# Ensure that we are in the folder containing this script
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Verify that access is denied for requests without a token or cookie
#
echo '1. Testing OPTIONS request ...'
HTTP_STATUS=$(curl -i -s -X OPTIONS "$API_URL" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** OPTIONS request failed, status: $HTTP_STATUS"
  exit
fi
echo '1. OPTIONS request was handled successfully'

#
# Verify that access is denied for GET requests without a token or cookie
#
echo '2. Testing POST with no credential ...'
HTTP_STATUS=$(curl -i -s -X POST "$API_URL" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '401' ]; then
  echo "*** POST wiht no credential failed, status: $HTTP_STATUS"
  exit
fi
echo '2. POST with no credential failed with the expected error'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq

#
# Verify that cookie requests from an untrusted web origin are rejected
#

#
# Verify that an access token sent from a mobile client is passed through to the API
#
echo '3. Testing POST from mobile client ...'
HTTP_STATUS=$(curl -i -s -X POST "$API_URL" \
-H 'Authorization: Bearer 678123egd2huor34' \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** POST from mobile client failed, status: $HTTP_STATUS"
  exit
fi
echo '3. POST from mobile client was handled successfully'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq

#
# Verify that a cookie sent on a GET request is correctly decrypted
#
echo '4. Testing GET with a valid encrypted cookie ...'
ENCRYPTED_ACCESS_TOKEN=$(node utils/encrypt.js "$ACCESS_TOKEN")
HTTP_STATUS=$(curl -i -s -X GET "$API_URL" \
-H "origin: $WEB_ORIGIN" \
-H "cookie: example-at=$ENCRYPTED_ACCESS_TOKEN" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** GET with a valid encrypted cookie failed, status: $HTTP_STATUS"
  exit
fi
echo '4. GET with a valid encrypted cookie was handled successfully'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq

#
# TODO: POST, OWASP checks etc
#