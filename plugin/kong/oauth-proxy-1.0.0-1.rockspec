package = "oauth-proxy"
version = "1.0.0-1"
source = {
  url = "."
}
description = {
  summary = "A Kong plugin used during API requests to decrypt AES256 encrypted cookies and forward access tokens"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.oauth-proxy.access"]  = "access.lua",
    ["kong.plugins.oauth-proxy.handler"] = "handler.lua",
    ["kong.plugins.oauth-proxy.schema"]  = "schema.lua"
  }
}
