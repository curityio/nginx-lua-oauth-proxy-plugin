--
-- The Kong entry point handler
--

local access = require "kong.plugins.oauth-proxy.access"

-- See https://github.com/Kong/kong/discussions/7193 for more about the PRIORITY field
local TokenHandler = {
    PRIORITY = 2000,
    VERSION = "1.3.1",
}

function TokenHandler:access(conf)
    access.run(conf)
end

return TokenHandler
