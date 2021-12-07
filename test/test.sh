#!/bin/bash

##########################################################################################
# The plugin depends on infrastructure that cannot easily run on desktop operating systems
# We therefore run some basic infrastructure tests against a deployed reverse proxy
##########################################################################################

API_URL='http://api.example.com:3000'
ACCESS_TOKEN='1234567890'
ENCRYPTED_ACCESS_TOKEN='551fbedfde28c548c5b43a8de98c7b59:0fe7776e602953598000d01c5dacd9af'
ENCRYPTION_KEY='NF65meV>Ls#8GP>;!Cnov)rIPRoK^.NP'
WEB_ORIGIN='http://www.example.com'
#export http_proxy='http://127.0.0.1:8888'

#EVP_DecryptFinal_ex failed

#
# Verify that access is denied for requests without a token or cookie
#
#curl $API_URL

#
# Verify that an access token sent from a mobile client is passed through to the API
#
#curl $API_URL -H "Authorization: Bearer $ACCESS_TOKEN"

#
# Verify that a cookie sent is correctly decrypted
#
curl $API_URL -H "origin: $WEB_ORIGIN" -H "cookie: example-at=$ENCRYPTED_ACCESS_TOKEN"