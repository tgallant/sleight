local lu = require('luaunit')

local sleight = {}

function sleight.parse(expr)
  return "foo"
end

function test_parse()
  local ast = sleight.parse("(+ 2 2)")
  lu.assertEquals(ast, "foo?")
end

os.exit(lu.LuaUnit.run())
