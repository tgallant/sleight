local lu = require('luaunit')

local sleight = {}

function sleight.foo()
  return 2
end

function test_assert()
  lu.assertEquals(2, sleight.foo())
end

os.exit(lu.LuaUnit.run())
