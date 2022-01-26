--
-- The Kong entry point handler
--

local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.oauth-proxy.access"

local TokenHandler = BasePlugin:extend()
TokenHandler.PRIORITY = 2000

function TokenHandler:new()
    TokenHandler.super.new(self, "oauth-proxy")
end

function TokenHandler:access(conf)
    TokenHandler.super.access(self)
    access.run(conf)
end

return TokenHandler
