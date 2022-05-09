FROM openresty/openresty:1.19.9.1-bionic

# Deploy the plugin and dependencies for local testing
COPY ./plugin/plugin.lua    /tmp/oauth-proxy/
COPY ./plugin/lua*.rockspec /tmp/oauth-proxy/
RUN cd /tmp/oauth-proxy/ && luarocks make lua-resty-oauth-proxy-1.0.0-1.rockspec
