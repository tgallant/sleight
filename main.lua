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
        local token = Token:new("Atom", value, line, col)
        table.insert(tokens, token)
        buffer = {}
      end
      local token = Token:new("RParen", char, line, col)
      table.insert(tokens, token)
      col = col + 1
    elseif char == " " then
      local value = table.concat(buffer, "")
      local token = Token:new("Atom", value, line, col)
      table.insert(tokens, token)
      buffer = {}
      col = col + 1
    elseif char == "\n" then
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
