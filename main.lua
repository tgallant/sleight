Token = {}

function Token:new(kind, lexeme, line, col)
  local new_token = {
    kind = kind,
    lexeme = lexeme,
    line = line,
    col = col,
  }
  self.__index = self
  return setmetatable(new_token, self)
end

function lex(expr)
  local tokens = {}
  local buffer = {}
  local line = 1
  local col = 1
  for char in string.gmatch(expr, ".") do
    if char == "(" then
      local token = Token:new("LParen", char, line, col)
      table.insert(tokens, token)
      col = col + 1
    elseif char == ")" then
      local value = table.concat(buffer, "")
      if value ~= "" then
        local col_start = col - #buffer
        local token = Token:new("Atom", value, line, col_start)
        table.insert(tokens, token)
        buffer = {}
      end
      local token = Token:new("RParen", char, line, col)
      table.insert(tokens, token)
      col = col + 1
    elseif char == " " and #buffer == 0 then
      col = col + 1
    elseif char == " " then
      local value = table.concat(buffer, "")
      local col_start = col - #buffer
      local token = Token:new("Atom", value, line, col_start)
      table.insert(tokens, token)
      buffer = {}
      col = col + 1
    elseif char == "\n" then
      local value = table.concat(buffer, "")
      if value ~= "" then
        local col_start = col - #buffer
        local token = Token:new("Atom", value, line, col_start)
        table.insert(tokens, token)
        buffer = {}
      end
      line = line + 1
      col = 1
    else
      table.insert(buffer, char)
      col = col + 1
    end
  end
  local eof = Token:new("EOF", nil, line, col)
  table.insert(tokens, eof)
  return tokens
end

Symbol = {}

function Symbol:new(value)
  local new_symbol = {
    kind = "Symbol",
    value = value,
  }
  self.__index = self
  return setmetatable(new_symbol, self)
end

Number = {}

function Number:new(value)
  local new_number = {
    kind = "Number",
    value = value,
  }
  self.__index = self
  return setmetatable(new_number, self)
end

List = {}

function List:new(value)
  local new_list = {
    kind = "List",
    value = value,
  }
  self.__index = self
  return setmetatable(new_list, self)
end

Parser = {}

function Parser:new(tokens)
  local new_parser = {
    tokens = tokens,
    current = 1,
    ast = {},
  }
  self.__index = self
  return setmetatable(new_parser, self)
end

function Parser:current_token()
  return self.tokens[self.current]
end

function Parser:is_end()
  local token = self:current_token()
  return token.kind == "EOF"
end

function Parser:advance()
  if not self:is_end() then
    self.current = self.current + 1
  end
end

function Parser:check(expected)
  local token = self:current_token()
  return token.kind == expected
end

function Parser:expect(expected)
  assert(self:check(expected), "expected " .. expected)
  self:advance()
end

function Parser:parse_list()
  self:expect("LParen")
  local value = {}
  while not self:check("RParen") and not self:is_end() do
    table.insert(value, self:parse_expr())
  end
  self:expect("RParen")
  return List:new(value)
end

function Parser:parse_expr()
  local token = self:current_token()
  if token.kind == "LParen" then
    return self:parse_list()
  elseif token.kind == "Atom" then
    self:advance()
    local num = tonumber(token.lexeme)
    if num then
      return Number:new(num)
    end
    return Symbol:new(token.lexeme)
  elseif token.kind == "RParen" then
    print("error: unexpected RParen")
  else
    print("unknown token?")
  end
end

function parse(tokens)
  local parser = Parser:new(tokens)
  return parser:parse_expr()
end

function read(expr)
  local tokens = lex(expr)
  local ast = parse(tokens)
  return ast
end

Environment = {}

function Environment:new()
  local new_environment = {
    bindings = {
      add = function(a, b)
        return a + b
      end,
      mult = function(a, b)
        return a * b
      end
    },
  }
  self.__index = self
  return setmetatable(new_environment, self)
end

function Environment:eval_list(elements)
  local args = {}
  for index, expr in ipairs(elements) do
    table.insert(args, self:eval_expr(expr))
  end
  local status, res = pcall(table.unpack(args))
  return res
end

function Environment:eval_expr(expr)
  if expr.kind == "Symbol" then
    return self.bindings[expr.value]
  elseif expr.kind == "Number" then
    return expr.value
  elseif expr.kind == "List" then
    return self:eval_list(expr.value)
  else
    return
  end
end

function eval(ast)
  local env = Environment:new()
  return env:eval_expr(ast)
end

function repl()
  local env = Environment:new()
  while true do
    io.write("> ")
    local expr = io.read()
    local ast = read(expr)
    local result = env:eval_expr(ast)
    io.write(tostring(result))
    io.write("\n")
  end
end

repl()

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '\n    ' .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '\n' .. '} '
  else
    return tostring(o)
  end
end

function pprint(tbl)
  print(dump(tbl))
end

function assert_num_tokens_lexed(tokens, expected)
  local eql = #tokens == expected
  if not eql then
    pprint(tokens)
  end
  local msg = "lexer produced " .. #tokens .. " tokens but expected " .. expected
  assert(eql, msg)
end

function assert_token_pos(token, line, col)
  local line_eql = token.line == line
  if not line_eql then
    pprint(token)
  end
  local line_msg = "token at line " .. token.line .. " but expected at " .. line
  assert(line_eql, line_msg)
  local col_eql = token.col == col
  if not col_eql then
    pprint(token)
  end
  local col_msg = "token at col " .. token.col .. " but expected at " .. col
  assert(col_eql, col_msg)
end

function test_lex()
  print("running test_lex...")
  local expr = "(add 2 (mult 3 4))"
  local tokens = lex(expr)
  assert_num_tokens_lexed(tokens, 10)
  assert_token_pos(tokens[1], 1, 1)
  assert_token_pos(tokens[2], 1, 2)
  assert_token_pos(tokens[3], 1, 6)
  assert_token_pos(tokens[4], 1, 8)
  assert_token_pos(tokens[5], 1, 9)
  assert_token_pos(tokens[6], 1, 14)
  assert_token_pos(tokens[7], 1, 16)
  assert_token_pos(tokens[8], 1, 17)
  assert_token_pos(tokens[9], 1, 18)
  assert_token_pos(tokens[10], 1, 19)
end

function test_lex_multiline()
  print("running test_lex_multiline...")
  local expr = [[(add 2
                   (mult 3 4))]]
  local tokens = lex(expr)
  assert_num_tokens_lexed(tokens, 10)
  assert_token_pos(tokens[1], 1, 1)
  assert_token_pos(tokens[2], 1, 2)
  assert_token_pos(tokens[3], 1, 6)
  assert_token_pos(tokens[4], 2, 20)
  assert_token_pos(tokens[5], 2, 21)
  assert_token_pos(tokens[6], 2, 26)
  assert_token_pos(tokens[7], 2, 28)
  assert_token_pos(tokens[8], 2, 29)
  assert_token_pos(tokens[9], 2, 30)
  assert_token_pos(tokens[10], 2, 31)
end

function assert_parser_current(val, expected)
  local msg = "parser.current is " .. val .. " but expected " .. expected
  assert(val == expected, msg)
end

function assert_parser_is_end(val, expected)
  local msg = "parser.is_end() is " .. tostring(val) .. " but expected " .. tostring(expected)
  assert(val == expected, msg)
end

function test_parser_current_token()
  print("running test_parser_current_token...")
  local expr = "(add 2 (mult 3 4))"
  local tokens = lex(expr)
  local parser = Parser:new(tokens)
  assert_parser_current(parser.current, 1)
  assert_token_pos(parser:current_token(), 1, 1)
  assert_parser_is_end(parser:is_end(), false)
  parser:advance()
  assert_parser_current(parser.current, 2)
  assert_token_pos(parser:current_token(), 1, 2)
  assert_parser_is_end(parser:is_end(), false)
  parser:advance()
  assert_parser_current(parser.current, 3)
  assert_token_pos(parser:current_token(), 1, 6)
  assert_parser_is_end(parser:is_end(), false)
  parser:advance()
  assert_parser_current(parser.current, 4)
  assert_token_pos(parser:current_token(), 1, 8)
  assert_parser_is_end(parser:is_end(), false)
  parser:advance()
  assert_parser_current(parser.current, 5)
  assert_token_pos(parser:current_token(), 1, 9)
  assert_parser_is_end(parser:is_end(), false)
  parser:advance()
  assert_parser_current(parser.current, 6)
  assert_token_pos(parser:current_token(), 1, 14)
  assert_parser_is_end(parser:is_end(), false)
  parser:advance()
  assert_parser_current(parser.current, 7)
  assert_token_pos(parser:current_token(), 1, 16)
  assert_parser_is_end(parser:is_end(), false)
  parser:advance()
  assert_parser_current(parser.current, 8)
  assert_token_pos(parser:current_token(), 1, 17)
  assert_parser_is_end(parser:is_end(), false)
  parser:advance()
  assert_parser_current(parser.current, 9)
  assert_token_pos(parser:current_token(), 1, 18)
  assert_parser_is_end(parser:is_end(), false)
  parser:advance()
  assert_parser_current(parser.current, 10)
  assert_token_pos(parser:current_token(), 1, 19)
  assert_parser_is_end(parser:is_end(), true)
end

function assert_expr_kind(value, expected)
  local msg = "got expression kind " .. value .. " expected " .. expected
  assert(value == expected, msg)
end

function assert_expr_value_len(value, expected)
  local msg = "got expression value length " .. value .. " expected " .. expected
  assert(value == expected, msg)
end

function test_parser_parse_expr_simple()
  print("running test_parser_parse_expr_simple...")
  local expr = "(add 2 2)"
  local tokens = lex(expr)
  local parser = Parser:new(tokens)
  local result = parser:parse_expr()
  assert_expr_kind(result.kind, "List")
  assert_expr_value_len(#result.value, 3)
  assert_expr_kind(result.value[1].kind, "Symbol")
  assert_expr_kind(result.value[2].kind, "Number")
  assert_expr_kind(result.value[3].kind, "Number")
end

function test_parser_parse_expr()
  print("running test_parser_parse_expr...")
  local expr = "(add 2 (mult 3 4))"
  local tokens = lex(expr)
  local parser = Parser:new(tokens)
  local result = parser:parse_expr()
  assert_expr_kind(result.kind, "List")
  assert_expr_value_len(#result.value, 3)
  assert_expr_kind(result.value[1].kind, "Symbol")
  assert_expr_kind(result.value[2].kind, "Number")
  assert_expr_kind(result.value[3].kind, "List")
  local nested = result.value[3]
  assert_expr_value_len(#nested.value, 3)
  assert_expr_kind(nested.value[1].kind, "Symbol")
  assert_expr_kind(nested.value[2].kind, "Number")
  assert_expr_kind(nested.value[3].kind, "Number")
end

function assert_eval_result(value, expected)
  local msg = "got eval result " .. value .. " expected " .. expected
  assert(value == expected, msg)
end

function test_eval_simple()
  print("running test_eval_simple...")
  local expr = "(add 2 2)"
  local ast = read(expr)
  local result = eval(ast)
  assert_eval_result(result, 4)
end

function test_eval()
  print("running test_eval...")
  local expr = "(add 2 (mult 3 4))"
  local ast = read(expr)
  local result = eval(ast)
  assert_eval_result(result, 14)
end

test_lex()
test_lex_multiline()
test_parser_current_token()
test_parser_parse_expr_simple()
test_parser_parse_expr()
test_eval_simple()
test_eval()
