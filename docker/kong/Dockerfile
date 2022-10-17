FROM kong:3.0.0-alpine

# Deploy the plugin and dependencies for local testing
USER root
COPY ./plugin/*.lua   /tmp/oauth-proxy/plugin/
COPY ./kong*.rockspec /tmp/oauth-proxy/
RUN cd /tmp/oauth-proxy && luarocks make kong-oauth-proxy-*.rockspec

USER kong