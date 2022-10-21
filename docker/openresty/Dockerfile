FROM openresty/openresty:1.21.4.1-bionic

# Deploy the plugin and dependencies for local testing
COPY ./lua*.rockspec     /tmp/oauth-proxy/
COPY ./plugin/access.lua /tmp/oauth-proxy/plugin/
RUN cd /tmp/oauth-proxy && luarocks make lua-resty-oauth-proxy-*.rockspec
