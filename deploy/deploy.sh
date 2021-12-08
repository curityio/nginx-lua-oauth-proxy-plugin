#!/bin/bash

######################################################################
# Deploy some infrastructure so that we can test the plugin's behavior
######################################################################

#
# Ensure that we are in the folder containing this script
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Get command line arguments
#
PROFILE=$1
if [ "$PROFILE" != 'openresty' ] && [ "$PROFILE" != 'kong' ]; then
  echo "Please specify 'openresty' or 'kong' as a command line argument, eg './deploy.sh openresty'"
  exit 1
fi

#
# Download this plugin which is not published to luarocks in an up to date manner
#
rm -rf lua-resty-cookie
git clone https://github.com/cloudflare/lua-resty-cookie lua-resty-cookie

#
# Deploy the system
#
docker compose --profile "$PROFILE" --project-name oauthproxy up --build --force-recreate