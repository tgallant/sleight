local sleight = require("sleight")
local Parser = sleight.Parser
local Environment = sleight.Environment
local lex = sleight.lex
local read = sleight.read
local eval = sleight.eval

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

function assert_token_value(token, value)
  local eql = token.lexeme == value
  if not eql then
    pprint(token)
  end
  local msg = "token has value " .. token.lexeme.. " but expected " .. value
  assert(eql, msg)
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

function test_lex_strings_simple()
  print("running test_lex_strings_simple...")
  local expr = '(print \"hello, world!\")'
  local tokens = lex(expr)
  assert_num_tokens_lexed(tokens, 5)
  assert_token_pos(tokens[1], 1, 1)
  assert_token_pos(tokens[2], 1, 2)
  assert_token_pos(tokens[3], 1, 8)
  assert_token_value(tokens[3], "hello, world!")
  assert_token_pos(tokens[4], 1, 23)
  assert_token_pos(tokens[5], 1, 24)
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

function test_parser_parse_expr_string_simple()
  print("running test_parser_parse_expr_string_simple...")
  local expr = '(print "hello, world!")'
  local tokens = lex(expr)
  local parser = Parser:new(tokens)
  local result = parser:parse_expr()
  assert_expr_kind(result.kind, "List")
  assert_expr_value_len(#result.value, 2)
  assert_expr_kind(result.value[1].kind, "Symbol")
  assert_expr_kind(result.value[2].kind, "String")
end

function test_parser_parse_expr_quote()
  print("running test_parser_parse_expr_quote...")
  local expr = "(cons 1 '(2 3))"
  local tokens = lex(expr)
  local parser = Parser:new(tokens)
  local result = parser:parse_expr()
  assert_expr_kind(result.kind, "List")
  assert_expr_value_len(#result.value, 3)
  assert_expr_kind(result.value[1].kind, "Symbol")
  assert_expr_kind(result.value[2].kind, "Number")
  assert_expr_kind(result.value[3].kind, "List")
  local quoted = result.value[3]
  assert_expr_value_len(#quoted.value, 2)
  assert_expr_kind(quoted.value[1].kind, "Symbol")
  local symbol = quoted.value[1].value
  assert(symbol == "quote", "got symbol " .. symbol .. " expected quote")
  assert_expr_kind(quoted.value[2].kind, "List")
  local quoted_list = quoted.value[2].value
  assert_expr_value_len(#quoted_list, 2)
  assert_expr_kind(quoted_list[1].kind, "Number")
  local first = quoted_list[1].value
  assert(first == 2, "got " .. first .. " expected 2")
  assert_expr_kind(quoted_list[2].kind, "Number")
  local second = quoted_list[2].value
  assert(second == 3, "got " .. second .. " expected 3")
end

function assert_eval_result(value, expected)
  if value == nil then
    value = "nil"
  end
  if expected == nil then
    expected = "nil"
  end
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

function test_eval_string_simple()
  print("running test_eval_string_simple...")
  local expr = "(print \"hello, world!\")"
  local ast = read(expr)
  local result = eval(ast)
  assert_eval_result(result, nil)
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

function test_eval_quote()
  print("running test_eval_quote...")
  local expr = "'x"
  local ast = read(expr)
  local result = eval(ast)
  assert(result["kind"] == "Symbol", "expected Symbol got " .. result["kind"])
  assert(result["value"] == "x", "expected x got " .. result["value"])
end

function test()
  test_lex()
  test_lex_multiline()
  test_lex_strings_simple()
  test_parser_current_token()
  test_parser_parse_expr_simple()
  test_parser_parse_expr()
  test_parser_parse_expr_string_simple()
  test_parser_parse_expr_quote()
  test_eval_simple()
  test_eval()
  test_eval_string_simple()
  test_eval_if()
  test_eval_if_else()
  test_define()
  test_lambda()
  test_apply()
  test_eval_quote()
end

test()
