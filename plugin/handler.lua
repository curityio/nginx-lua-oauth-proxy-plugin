local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.bff-token.access"

local TokenHandler = BasePlugin:extend()
TokenHandler.PRIORITY = 2000

function TokenHandler:new()
    TokenHandler.super.new(self, "bff-token")
end

function TokenHandler:access(conf)
    TokenHandler.super.access(self)
    access.run(conf)
end

return TokenHandler
