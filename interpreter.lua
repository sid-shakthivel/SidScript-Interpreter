Token = { value, type }

INTEGER, PLUS, MINUS, TIMES, DIVIDE, EOF = "INTEGER", "PLUS", "MINUS", "TIMES", "DIVIDE", "EOF"

function Token:new (value, type)
    setmetatable({}, Token);
    self.value = value
    self.type = type
    return self
end

function Token:getAttributes()
    print("TYPE:", self.type, " VALUE:", self.value)
end

Lexer = { input, pos }

function Lexer:new (input)
    setmetatable({}, Lexer)
    self.input = input
    self.pos = 0;
    return self
end

function Lexer:getNextToken()
    self.pos = self.pos + 1
    if (tonumber(self.input:sub(self.pos, self.pos))) then
        return Token:new(tonumber(self.input:sub(self.pos, self.pos)), INTEGER)
    elseif (self.input:sub(self.pos, self.pos) == '+') then
        return Token:new('+', PLUS)
    elseif (self.input:sub(self.pos, self.pos) == '-') then
        return Token:new('-', MINUS)
    elseif (self.input:sub(self.pos, self.pos) == '*') then
        return Token:new('*', TIMES)
    elseif (self.input:sub(self.pos, self.pos) == '/') then
        return Token:new('/', DIVIDE)
    elseif (self.input:sub(self.pos, self.pos) == ' ') then
        return self:getNextToken()
    else
        return Token:new(nil, EOF)
    end
end

function Lexer:getNumber()
    digits = ""
    while true do
        newToken = self:getNextToken()
        if (newToken.type ~= INTEGER) then
            break
        end
        digits = digits .. tostring(newToken.value)
    end
    self.pos = self.pos - 1
    if (digits == "") then
        return "DONE"
    else
        return tonumber(digits)
    end
end

function Lexer:calculateSum(sign, left, right)
    sign = sign and tonumber(sign) or sign
    case = {
        ['+'] = function()
            return left + right
        end,
        ['-'] = function()
            return left - right
        end,
        ['*'] = function()
            return left * right
        end,
        ['/'] = function()
            return left / right
        end,
    }

    return case[sign]()
end

function Lexer:evaluate()
    sum = self:getNumber()

    while true do
        sign = self:getNextToken().value
        nextNum = self:getNumber()
        if (nextNum == "DONE") then
            break
        end
        sum = self:calculateSum(sign, sum, nextNum)
    end

    print(tostring(sum))
end

while true do
    input = io.read("*l")
    lexer = Lexer:new(input)
    lexer:evaluate()
end
