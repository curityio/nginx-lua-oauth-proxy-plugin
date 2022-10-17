
#!/bin/bash

################################################################################################
# After installing these prerequisites, this deploys the latest LUA code and runs all unit tests
# - brew install openresty/brew/openresty
# - cpan Test::Nginx
################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Point to the OpenResty install
#
OPENRESTY_ROOT=/usr/local/Cellar/openresty/1.21.4.1_1

#
# Ensure that the OpenResty nginx, with LUA support, will be found by the prove tool
#
export PATH=${PATH}:"$OPENRESTY_ROOT/nginx/sbin"

#
# Copy the latest plugin to the LUA libraries folder
#
cp plugin/plugin.lua "$OPENRESTY_ROOT/lualib/oauth-proxy.lua"

#
# Run all tests
#
prove -v -f t/*.t