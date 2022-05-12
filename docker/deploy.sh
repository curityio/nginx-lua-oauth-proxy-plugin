#!/bin/bash

######################################################################
# Deploy some infrastructure so that we can test the plugin's behavior
######################################################################

#
# Ensure that we are in the root folder
#
cd "$(dirname "${BASH_SOURCE[0]}")"
cd ..

#
# Get command line arguments
#
PROFILE=$1
if [ "$PROFILE" != 'openresty' ] && [ "$PROFILE" != 'kong' ]; then
  echo "Please specify 'openresty' or 'kong' as a command line argument, eg './deploy.sh openresty'"
  exit 1
fi

#
# Supply the 32 byte encryption key for AES256 as an environment variable
#
export ENCRYPTION_KEY=$(openssl rand 32 | xxd -p -c 64)
echo -n $ENCRYPTION_KEY > docker/encryption.key

#
# For Kong we must update a template file
#
if [ "$PROFILE" == 'kong' ]; then
  envsubst < docker/kong/kong.template.yml > docker/kong/kong.yml
fi

#
# Build a custom Docker image, which uses 'luarocks make' to deploy the plugin
#
if [ "$PROFILE" == 'kong' ]; then
  docker build -f docker/kong/Dockerfile --no-cache -t custom_kong:2.6.0-alpine .
else
  docker build -f docker/openresty/Dockerfile --no-cache -t custom_openresty:1.19.9.1-bionic .
fi
if [ $? -ne 0 ]; then
  echo "Problem encountered building the OAuth Proxy Docker file"
  exit 1
fi  

#
# Deploy the system
#
docker compose --file ./docker/docker-compose.yml --profile "$PROFILE" --project-name oauthproxy up --build --force-recreate