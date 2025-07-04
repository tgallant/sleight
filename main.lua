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

Lexer = {}

function Lexer:new()
  local new_lexer = {
    tokens = {},
    buffer = {},
    line = 1,
    col = 1,
  }
  self.__index = self
  return setmetatable(new_lexer, self)
end

function Lexer:advance_col()
  self.col = self.col + 1
end

function Lexer:advance_line()
  self.line = self.line + 1
  self.col = 1
end

function Lexer:clear_buffer()
  local value = table.concat(self.buffer, "")
  if value ~= "" then
    local col_start = self.col - #self.buffer
    local token = Token:new("Atom", value, self.line, col_start)
    table.insert(self.tokens, token)
    self.buffer = {}
  end
end

function Lexer:handle_lparen()
  local token = Token:new("LParen", "(", self.line, self.col)
  table.insert(self.tokens, token)
  self:advance_col()
end

function Lexer:handle_rparen()
  self:clear_buffer()
  local token = Token:new("RParen", ")", self.line, self.col)
  table.insert(self.tokens, token)
  self:advance_col()
end

function Lexer:handle_atom()
  self:clear_buffer()
  self:advance_col()
end

function Lexer:handle_newline()
  self:clear_buffer()
  self:advance_line()
end

function Lexer:handle_eof()
  local eof = Token:new("EOF", nil, self.line, self.col)
  table.insert(self.tokens, eof)
end

function Lexer:lex(expr)
  for char in string.gmatch(expr, ".") do
    if char == "(" then
      self:handle_lparen()
    elseif char == ")" then
      self:handle_rparen()
    elseif char == " " and #self.buffer == 0 then
      self:advance_col()
    elseif char == " " then
      self:handle_atom()
    elseif char == "\n" then
      self:handle_newline()
    else
      table.insert(self.buffer, char)
      self:advance_col()
    end
  end
  self:clear_buffer()
  self:handle_eof()
  return self.tokens
end

function lex(expr)
  local lexer = Lexer:new()
  return lexer:lex(expr)
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

Function = {}

function Function:new(params, body, closure)
  local new_fn = {
    kind = "Function",
    params = params,
    body = body,
    closure = closure,
  }
  self.__index = self
  return setmetatable(new_fn, self)
end

Environment = {}

function Environment:new()
  local new_environment = {
    bindings = {
      ["+"] = function(a, b)
        return a + b
      end,
      ["-"] = function(a, b)
        return a - b
      end,
      ["*"] = function(a, b)
        return a * b
      end,
      ["/"] = function(a, b)
        return a / b
      end,
      ["="] = function(a, b)
        return a == b
      end,
      [">"] = function(a, b)
        return a > b
      end,
      [">="] = function(a, b)
        return a >= b
      end,
      ["<"] = function(a, b)
        return a < b
      end,
      ["<="] = function(a, b)
        return a <= b
      end,
    },
  }
  self.__index = self
  return setmetatable(new_environment, self)
end

function Environment:copy()
  local new_environment = {
    bindings = {}
  }
  for key, value in pairs(self.bindings) do
    new_environment.bindings[key] = value
  end
  self.__index = self
  return setmetatable(new_environment, self)
end

function Environment:eval_if(args)
  assert(#args == 4, "invalid arity: if expects 3 arguments")
  if self:eval_expr(args[2]) then
    return self:eval_expr(args[3])
  else
    return self:eval_expr(args[4])
  end
end

function Environment:eval_define(args)
  assert(#args == 3, "invalid arity: define expects 2 arguments")
  if args[3].kind == "List" then
    self.bindings[args[2].value] = self:eval_expr(args[3])
  else
    self.bindings[args[2].value] = args[3].value
  end
end

function Environment:eval_lambda(args)
  assert(#args == 3, "invalid arity: lambda expects 2 arguments")
  local params = args[2]
  local body = args[3]
  local closure = self:copy()
  return Function:new(params, body, closure)
end

function Environment:apply(elements)
  local args = {}
  for index, expr in ipairs(elements) do
    table.insert(args, self:eval_expr(expr))
  end
  local fn = args[1]
  if type(fn) == "function" then
    local status, res = pcall(table.unpack(args))
    return res
  elseif fn.kind == "Function" then
    assert(#fn.params.value == #args - 1, "function receieved incorrect number or params")
    for i = 1, #fn.params.value, 1 do
      fn.closure.bindings[fn.params.value[i].value] = args[i + 1]
    end
    return fn.closure:eval_expr(fn.body)
  else
    print("error: invalid function type")
  end
end

function Environment:eval_list(elements)
  local first = elements[1]
  local is_symbol = first.kind == "Symbol"
  if is_symbol and first.value == "if" then
    return self:eval_if(elements)
  elseif is_symbol and first.value == "define" then
    return self:eval_define(elements)
  elseif is_symbol and first.value == "lambda" then
    return self:eval_lambda(elements)
  else
    return self:apply(elements)
  end
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
  local expr = "(+ 2 2)"
  local ast = read(expr)
  local result = eval(ast)
  assert_eval_result(result, 4)
end

function test_eval()
  print("running test_eval...")
  local expr = "(+ 2 (* 3 4))"
  local ast = read(expr)
  local result = eval(ast)
  assert_eval_result(result, 14)
end

function test_eval_if()
  print("running test_eval_if...")
  local expr = "(if (= 2 2) (* 1 1) (+ 1 1))"
  local ast = read(expr)
  local result = eval(ast)
  assert_eval_result(result, 1)
end

function test_eval_if_else()
  print("running test_eval_if_else...")
  local expr = "(if (= 1 2) (* 1 1) (+ 1 1))"
  local ast = read(expr)
  local result = eval(ast)
  assert_eval_result(result, 2)
end

function test_define()
  print("running test_define...")
  local expr = "(define foo 123)"
  local ast = read(expr)
  local env = Environment:new()
  env:eval_expr(ast)
  local foo = env.bindings["foo"]
  local eql = foo == 123
  local msg = "got binding value " .. foo .. " expected " .. 123
  assert(eql, msg)
end

function test_lambda()
  print("running test_lambda...")
  local expr = "(lambda (x) (+ x 1))"
  local ast = read(expr)
  local env = Environment:new()
  local fn = env:eval_expr(ast)
  assert(fn.kind == "Function", "got kind " .. fn.kind .. " expected" .. "Function")
  assert(fn.params.kind == "List", "expected function params to be a list")
  assert(#fn.params.value == 1, "expected function to have 1 parameter")
  assert(fn.params.value[1].kind == "Symbol", "expected parameter to be a Symbol")
  assert(fn.params.value[1].value == "x", "expected parameter to be the Symbol x")
  assert(fn.body.kind == "List", "expected function body to be a list")
  assert(#fn.body.value == 3, "expected function body to have 3 elements")
  assert(fn.body.value[1].kind == "Symbol", "expected parameter to be a Symbol")
  assert(fn.body.value[1].value == "+", "expected parameter to be the Symbol +")
end

function test_apply()
  print("running test_apply...")
  local expr = "(define incr (lambda (x) (+ x 1)))"
  local ast = read(expr)
  local env = Environment:new()
  env:eval_expr(ast)
  local fn_expr = "(incr 41)"
  local fn_ast = read(fn_expr)
  local result = env:eval_expr(fn_ast)
  assert(result == 42, "func returned " .. result .. " expected " .. 42)
end

function test()
  test_lex()
  test_lex_multiline()
  test_parser_current_token()
  test_parser_parse_expr_simple()
  test_parser_parse_expr()
  test_eval_simple()
  test_eval()
  test_eval_if()
  test_eval_if_else()
  test_define()
  test_lambda()
  test_apply()
end


function main()
  if #arg == 0 then
    repl()
  elseif arg[1] == "test" then
    test()
  end
end

main()
