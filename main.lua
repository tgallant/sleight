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
  return tokens
end

function parse(tokens)
  return "foo"
end

function read(expr)
  local tokens = lex(expr)
  local ast = parse(tokens)
  return ast
end

function eval(expr)
  local tokens = sleight.lex(expr)
  local ast = sleight.parse(tokens)
  return "foo"
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
  assert_num_tokens_lexed(tokens, 9)
  assert_token_pos(tokens[1], 1, 1)
  assert_token_pos(tokens[2], 1, 2)
  assert_token_pos(tokens[3], 1, 6)
  assert_token_pos(tokens[4], 1, 8)
  assert_token_pos(tokens[5], 1, 9)
  assert_token_pos(tokens[6], 1, 14)
  assert_token_pos(tokens[7], 1, 16)
  assert_token_pos(tokens[8], 1, 17)
  assert_token_pos(tokens[9], 1, 18)
end

function test_lex_multiline()
  print("running test_lex_multiline...")
  local expr = [[(add 2
                   (mult 3 4))]]
  local tokens = lex(expr)
  assert_num_tokens_lexed(tokens, 9)
  assert_token_pos(tokens[1], 1, 1)
  assert_token_pos(tokens[2], 1, 2)
  assert_token_pos(tokens[3], 1, 6)
  assert_token_pos(tokens[4], 2, 20)
  assert_token_pos(tokens[5], 2, 21)
  assert_token_pos(tokens[6], 2, 26)
  assert_token_pos(tokens[7], 2, 28)
  assert_token_pos(tokens[8], 2, 29)
  assert_token_pos(tokens[9], 2, 30)
end

test_lex()
test_lex_multiline()
