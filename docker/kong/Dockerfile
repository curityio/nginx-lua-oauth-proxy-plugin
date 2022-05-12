FROM kong:2.6.0-alpine

# Deploy the plugin and dependencies for local testing
USER root
COPY ./plugin/*.lua          /tmp/oauth-proxy/
COPY ./plugin/kong*.rockspec /tmp/oauth-proxy/
RUN cd /tmp/oauth-proxy/ && luarocks make kong-oauth-proxy-1.0.0-1.rockspec

USER kong