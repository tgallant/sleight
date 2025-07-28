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
    string_open = false,
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

function Lexer:add_to_buffer(char)
  table.insert(self.buffer, char)
  self:advance_col()
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

function Lexer:handle_quote()
  local token = Token:new("Quote", "'", self.line, self.col)
  table.insert(self.tokens, token)
  self:advance_col()
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

function Lexer:handle_string()
  if self.string_open then
    self.string_open = false
    local value = table.concat(self.buffer, "")
    if value ~= "" then
      local col_start = self.col - #self.buffer - 1
      local token = Token:new("String", value, self.line, col_start)
      table.insert(self.tokens, token)
      self.buffer = {}
    end
  else
    self.string_open = true
  end
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
    if char == "\"" then
      self:handle_string()
    elseif self.string_open then
      self:add_to_buffer(char)
    elseif char == "'" then
      self:handle_quote()
    elseif char == "(" then
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
      self:add_to_buffer(char)
    end
  end
  self:clear_buffer()
  self:handle_eof()
  return self.tokens
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

String = {}

function String:new(value)
  local new_string = {
    kind = "String",
    value = value,
  }
  self.__index = self
  return setmetatable(new_string, self)
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

Boolean = {
  ["True"] = {
    kind = "Boolean",
    value = true
  },
  ["False"] = {
    kind = "Boolean",
    value = false
  },
}

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

function Parser:parse_atom()
  local token = self:current_token()
  self:advance()
  if token.lexeme == "#t" then
    return Boolean.True
  elseif token.lexeme == "#f" then
    return Boolean.False
  end
  local num = tonumber(token.lexeme)
  if num then
    return Number:new(num)
  end
  return Symbol:new(token.lexeme)
end

function Parser:parse_quote()
  self:expect("Quote")
  local value = {Symbol:new("quote"), self:parse_expr()}
  return List:new(value)
end

function Parser:parse_expr()
  local token = self:current_token()
  if token.kind == "Quote" then
    return self:parse_quote()
  elseif token.kind == "LParen" then
    return self:parse_list()
  elseif token.kind == "Atom" then
    return self:parse_atom()
  elseif token.kind == "String" then
    self:advance()
    return String:new(token.lexeme)
  elseif token.kind == "RParen" then
    print("error: unexpected RParen")
  else
    print("unknown token?")
  end
end

function Parser:parse()
  local ast = {}
  local begin = Symbol:new("begin")
  table.insert(ast, begin)
  while not self:is_end() do
    local expr = self:parse_expr()
    table.insert(ast, expr)
  end
  return List:new(ast)
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

Macro = {}

function Macro:new(params, body, closure)
  local new_macro = {
    kind = "Macro",
    params = params,
    body = body,
    closure = closure,
  }
  self.__index = self
  return setmetatable(new_macro, self)
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
      ["cons"] = function(a, b)
        return {a, b}
      end,
      ["car"] = function(p)
        return p[1]
      end,
      ["cdr"] = function(p)
        return p[2]
      end,
      ["number?"] = function(a)
        return type(a) == "number"
      end,
      ["string?"] = function(a)
        return type(a) == "string"
      end,
      ["boolean?"] = function(a)
        return type(a) == "boolean"
      end,
      ["symbol?"] = function(a)
        if type(a) ~= "table" then
          return false
        end
        return a.kind == "Symbol"
      end,
      ["list?"] = function(a)
        if type(a) ~= "table" then
          return false
        end
        return a.kind == "List"
      end,
      ["null?"] = function(a)
        return type(a) == nil
      end,
      ["print"] = function(a)
        print(a)
      end,
      ["assert"] = assert,
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

function Environment:expand_macro(args)
  assert(#args == 3, "invalid arity: define-macro expects 2 arguments")
  if args[3].kind == "List" then
    self.bindings[args[2].value] = self:eval_expr(args[3])
  else
    self.bindings[args[2].value] = args[3].value
  end
end

function Environment:eval_define_macro(args)
  assert(#args == 3, "invalid arity: define-macro expects 2 arguments")
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
    local res = self:eval_expr(expr)
    table.insert(args, self:eval_expr(expr))
  end
  local fn = args[1]
  if type(fn) == "function" then
    local status, res = pcall(table.unpack(args))
    assert(status, res)
    return res
  elseif fn.kind == "Function" then
    assert(#fn.params.value == #args - 1, "function receieved incorrect number or params")
    for i = 1, #fn.params.value, 1 do
      fn.closure.bindings[fn.params.value[i].value] = args[i + 1]
    end
    return fn.closure:eval_expr(fn.body)
  elseif fn.kind == "Macro" then
    assert(#fn.params.value == #args - 1, "macro receieved incorrect number or params")
    for i = 1, #fn.params.value, 1 do
      fn.closure.bindings[fn.params.value[i].value] = args[i + 1]
    end
    local expanded = self:expand_macro(fn)
    return fn.closure:eval_expr(expanded)
  else
    print("error: invalid function type")
  end
end

function Environment:eval_begin(elements)
  local result = nil
  for index, expr in ipairs(elements) do
    if index > 1 then
      result = self:eval_expr(expr)
    end
  end
  return result
end

function Environment:eval_quote(elements)
  assert(#elements == 2, "invalid arity: quote expects 1 argument")
  return elements[2]
end

function Environment:eval_list(elements)
  local first = elements[1]
  local is_symbol = first.kind == "Symbol"
  if is_symbol and first.value == "if" then
    return self:eval_if(elements)
  elseif is_symbol and first.value == "define" then
    return self:eval_define(elements)
  elseif is_symbol and first.value == "define-macro" then
    return self:eval_define_macro(elements)
  elseif is_symbol and first.value == "lambda" then
    return self:eval_lambda(elements)
  elseif is_symbol and first.value == "begin" then
    return self:eval_begin(elements)
  elseif is_symbol and first.value == "quote" then
    return self:eval_quote(elements)
  else
    return self:apply(elements)
  end
end

function Environment:eval_expr(expr)
  if expr.kind == "Symbol" then
    return self.bindings[expr.value]
  elseif expr.kind == "Number" then
    return expr.value
  elseif expr.kind == "String" then
    return expr.value
  elseif expr.kind == "Boolean" then
    return expr.value
  elseif expr.kind == "List" then
    return self:eval_list(expr.value)
  else
    return
  end
end

function lex(expr)
  local lexer = Lexer:new()
  return lexer:lex(expr)
end

function parse(tokens)
  local parser = Parser:new(tokens)
  return parser:parse()
end

function read(expr)
  local tokens = lex(expr)
  local ast = parse(tokens)
  return ast
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

function run_file(path)
  local file = io.open(path, "r")
  if not file then
    print("Error opening file")
    return
  end
  local content = file:read("*a")
  file:close()
  local ast = read(content)
  eval(ast)
end

return {
  Parser = Parser,
  Environment = Environment,
  lex = lex,
  parse = parse,
  read = read,
  eval = eval,
  repl = repl,
  run_file = run_file,
}
