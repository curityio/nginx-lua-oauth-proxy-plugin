--
-- The Kong entry point handler
--

local access = require "kong.plugins.oauth-proxy.access"

local TokenHandler = {
    PRIORITY = 2000,
    VERSION = "1.3.0",
}

function TokenHandler:access(conf)
    access.run(conf)
end

return TokenHandler
