#!/bin/bash

##########################################################################################
# The plugin depends on infrastructure that cannot easily run on desktop operating systems
# We therefore run some basic infrastructure tests against a deployed reverse proxy
##########################################################################################

API_URL='http://localhost:3000'
WEB_ORIGIN='http://www.example.com'
ACCESS_TOKEN='42665300-efe8-419d-be52-07b53e208f46'
CSRF_TOKEN='abc'
RESPONSE_FILE=response.txt

#
# Ensure that we are in the folder containing this script
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Get a header value from the HTTP response file
#
function getHeaderValue(){
  local _HEADER_NAME=$1
  local _HEADER_VALUE=$(cat $RESPONSE_FILE | grep -i "^$_HEADER_NAME" | sed -r "s/^$_HEADER_NAME: (.*)$/\1/i")
  local _HEADER_VALUE=${_HEADER_VALUE%$'\r'}
  echo $_HEADER_VALUE
}

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
echo '1. OPTIONS request was handled successfully by the plugin'

#
# Verify that access is denied for GET requests without a token or cookie
#
echo '2. Testing POST with no credential ...'
HTTP_STATUS=$(curl -i -s -X POST "$API_URL" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '401' ]; then
  echo '*** POST with no credential did not result in the expected error'
  exit
fi
echo '2. POST with no credential failed with the expected error'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq

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
echo '3. POST from mobile client was successfully routed to the API'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq

#
# Verify that cookie requests from an untrusted web origin are rejected
#
echo '4. Testing GET from an untrusted web origin ...'
ENCRYPTED_ACCESS_TOKEN=$(node utils/encrypt.js "$ACCESS_TOKEN")
HTTP_STATUS=$(curl -i -s -X GET "$API_URL" \
-H "origin: https://malicious-site.com" \
-H "cookie: example-at=$ENCRYPTED_ACCESS_TOKEN" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '401' ]; then
  echo '*** GET from an untrusted web origin did not result in the expected error'
  exit
fi
ORIGIN=$(getHeaderValue 'Access-Control-Allow-Origin')
if [ "$ORIGIN" != '' ]; then
  echo '*** CORS access was granted to a malicious origin'
  exit
fi
echo '4. GET from an untrusted web origin was handled correctly'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq

#
# Verify that SPA clients can read error responses from the plugin, by sending no credential but the correct origin
#
echo '5. Testing CORS headers for error responses to the SPA ...'
HTTP_STATUS=$(curl -i -s -X POST "$API_URL" \
-H "origin: $WEB_ORIGIN" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '401' ]; then
  echo '*** Request with no credential did not result in the expected error'
  exit
fi
ORIGIN=$(getHeaderValue 'Access-Control-Allow-Origin')
if [ "$ORIGIN" != "$WEB_ORIGIN" ]; then
  echo '*** CORS headers do not allow the SPA to read the error response'
  exit
fi
echo '5. CORS error responses to the SPA have the correct headers'

#
# Verify that a cookie sent on a GET request is correctly decrypted
#
echo '6. Testing GET with a valid encrypted cookie ...'
ENCRYPTED_ACCESS_TOKEN=$(node utils/encrypt.js "$ACCESS_TOKEN")
HTTP_STATUS=$(curl -i -s -X GET "$API_URL" \
-H "origin: $WEB_ORIGIN" \
-H "cookie: example-at=$ENCRYPTED_ACCESS_TOKEN" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** GET with a valid encrypted cookie failed, status: $HTTP_STATUS"
  exit
fi
echo '6. GET with a valid encrypted cookie was successfully routed to the API'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq

#
# Verify that data changing commands require a CSRF cookie
#
echo '7. Testing POST with missing CSRF cookie ...'
ENCRYPTED_ACCESS_TOKEN=$(node utils/encrypt.js "$ACCESS_TOKEN")
HTTP_STATUS=$(curl -i -s -X POST "$API_URL" \
-H "origin: $WEB_ORIGIN" \
-H "cookie: example-at=$ENCRYPTED_ACCESS_TOKEN" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '401' ]; then
  echo '*** POST with a missing CSRF cookie did not result in the expected error'
  exit
fi
echo '7. POST with a missing CSRF cookie was successfully rejected'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq

#
# Verify that data changing commands require a CSRF header
#
echo '8. Testing POST with missing CSRF header ...'
ENCRYPTED_ACCESS_TOKEN=$(node utils/encrypt.js "$ACCESS_TOKEN")
ENCRYPTED_CSRF_TOKEN=$(node utils/encrypt.js "$CSRF_TOKEN")
HTTP_STATUS=$(curl -i -s -X POST "$API_URL" \
-H "origin: $WEB_ORIGIN" \
-H "cookie: example-at=$ENCRYPTED_ACCESS_TOKEN" \
-H "cookie: example-csrf=$ENCRYPTED_CSRF_TOKEN" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '401' ]; then
  echo '*** POST with a missing CSRF header did not result in the expected error'
  exit
fi
echo '8. POST with a missing CSRF header was successfully rejected'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq

#
# Verify that double submit cookie checks work if the cookie and value do not match
#
echo '9. Testing POST with incorrect CSRF header ...'
ENCRYPTED_ACCESS_TOKEN=$(node utils/encrypt.js "$ACCESS_TOKEN")
ENCRYPTED_CSRF_TOKEN=$(node utils/encrypt.js "$CSRF_TOKEN")
HTTP_STATUS=$(curl -i -s -X POST "$API_URL" \
-H "origin: $WEB_ORIGIN" \
-H "cookie: example-at=$ENCRYPTED_ACCESS_TOKEN" \
-H "cookie: example-csrf=$ENCRYPTED_CSRF_TOKEN" \
-H "x-example-csrf: x$CSRF_TOKEN" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '401' ]; then
  echo '*** POST with an incorrect CSRF header did not result in the expected error'
  exit
fi
echo '9. POST with an incorrect CSRF header was successfully rejected'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq

#
# Verify that double submit cookie checks succeed with the correct data
#
echo '10. Testing POST with correct CSRF cookie and header ...'
ENCRYPTED_ACCESS_TOKEN=$(node utils/encrypt.js "$ACCESS_TOKEN")
ENCRYPTED_CSRF_TOKEN=$(node utils/encrypt.js "$CSRF_TOKEN")
HTTP_STATUS=$(curl -i -s -X POST "$API_URL" \
-H "origin: $WEB_ORIGIN" \
-H "cookie: example-at=$ENCRYPTED_ACCESS_TOKEN" \
-H "cookie: example-csrf=$ENCRYPTED_CSRF_TOKEN" \
-H "x-example-csrf: $CSRF_TOKEN" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo '*** POST with correct CSRF cookie and header did not succeed'
  exit
fi
echo '10. POST with correct CSRF cookie and header was successfully routed to the API'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq


#
# Verify that malformed cookies are correctly rejected
#
echo '11. Testing GET with malformed access token cookie ...'
ENCRYPTED_ACCESS_TOKEN=$(node utils/encrypt.js "$ACCESS_TOKEN")
HTTP_STATUS=$(curl -i -s -X GET "$API_URL" \
-H "origin: $WEB_ORIGIN" \
-H "cookie: example-at=" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '401' ]; then
  echo '*** GET with malformed access token cookie did not result in the expected error'
  exit
fi
echo '11. GET with malformed access token cookie was successfully rejected'
JSON=$(tail -n 1 $RESPONSE_FILE)
echo $JSON | jq
