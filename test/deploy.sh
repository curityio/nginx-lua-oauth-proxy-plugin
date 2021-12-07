#!/bin/bash

########################################################################
# Deploy some infrastructure so that we can test the plugin's conditions
########################################################################

docker compose --project-name oauth-proxy up --build --force-recreate