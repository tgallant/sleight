#!/bin/bash

lua_tests() {
    LUA_ENV=./?.lua:$LUA_ENV lua tests.lua
}

scm_tests() {
    ./sleight scm/t.scm
}

lua_tests && scm_tests
