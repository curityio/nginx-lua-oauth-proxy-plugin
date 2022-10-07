package = "kong-oauth-proxy"
version = "1.2.0-1"
source = {
  url = "git://github.com/curityio/nginx-lua-oauth-proxy-plugin",
  tag = "v1.2.0"
}
description = {
  summary = "A plugin used during API requests to deal with CORS and cookies, then forward access tokens",
  homepage = "https://curity.io/product/token-service/oauth-for-web/",
  license = "Apache 2.0",
  detailed = [[
        The Curity OAuth Proxy is a LUA library used when Single Page Applications (SPAs) call APIs.
        This version is designed to be used by Kong API Gateway, including the open source version.
        Secure cookies are first issued to the SPA by a separate token handler (OAuth Agent).
        During API requests the plugin first validates web origins against a whitelist of trusted origins.
        It then provides CORS responses headers needed for the SPA to make cross origin requests.
        During API requests the OAuth Proxy implements Cross Site Request Forgery protection when needed.
        It then decrypts secure cookies to get the access token contained.
        The access token is then forwarded to the API using the HTTP Authorization header.
        All of this provides strongest browser security without needing any API code changes.
  ]],
  summary = "A Kong plugin used during API requests to deal with CORS and cookies, then forward access tokens"
}
dependencies = {
  "lua >= 5.1",
  "lua-resty-openssl >= 0.8.4"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.oauth-proxy.access"]  = "plugin/plugin.lua",
    ["kong.plugins.oauth-proxy.handler"] = "plugin/handler.lua",
    ["kong.plugins.oauth-proxy.schema"]  = "plugin/schema.lua"
  }
}
