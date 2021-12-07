ngx = {}

local lu = require "luaunit"
local plugin = require ".plugin.access"

TestTokenPlugin = {}

    function TestTokenPlugin:testRun1()
        local result = access.testRun(3, 4)
        lu.assertEquals( result, 7 )
    end

    function TestTokenPlugin:testRun2()
        local result = access.testRun(3, 4)
        lu.assertEquals( result, 8 )
    end

os.exit( lu.LuaUnit.run() )