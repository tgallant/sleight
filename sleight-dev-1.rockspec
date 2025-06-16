package = "sleight"
rockspec_format = "3.0"
version = "dev-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   summary = "Sleight is a toy scheme implementation written in lua.",
   detailed = [[
Sleight is a toy scheme implementation written in lua.
]],
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {
   "lua ~> 5.4",
}
build_dependencies = {
}
build = {
   type = "builtin",
   modules = {
      main = "src/main.lua"
   }
}
test_dependencies = {
  "luaunit == 3.4-1"
}
