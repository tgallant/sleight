local sleight = require("sleight")

local function main()
  if #arg == 0 then
    sleight.repl()
  elseif #arg == 1 then
     sleight.run_file(arg[1])
  end
end

main()
