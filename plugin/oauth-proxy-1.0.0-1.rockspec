package = "oauth-proxy"
version = "1.0.0-1"
source = {
  url = "."
}
description = {
  summary = "A Kong custom plugin that decrypts secure cookies and reads access tokens"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.phantom-token.access"] = "access.lua",
    ["kong.plugins.phantom-token.handler"] = "handler.lua",
    ["kong.plugins.phantom-token.schema"] = "schema.lua"
  }
}
