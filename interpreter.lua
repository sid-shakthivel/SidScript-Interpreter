Token = { value, type }

INTEGER, ADD, MIN, MUL, DIV, EOF = "INTEGER", "ADD", "MIN", "MUL", "DIV", "EOF"

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
    self.pos = 1;
    return self
end

function Lexer:getNextToken()
    if (self.input:sub(self.pos, self.pos) == ' ') then
        self.pos = self.pos + 1
    end

    token = nil
    case = {
        ['+'] = function()
            token = Token:new('+', ADD)
        end,
        ['-'] = function()
            token = Token:new('-', MIN)
        end,
        ['*'] = function()
            token = Token:new('*', MUL)
        end,
        ['/'] = function()
            token = Token:new('/', DIV)
        end,
    }

    if (tonumber(self.input:sub(self.pos, self.pos))) then
        token = Token:new(tonumber(self.input:sub(self.pos, self.pos)), INTEGER)
    else
        if (case[self.input:sub(self.pos, self.pos)]) then
            case[self.input:sub(self.pos, self.pos)]()
        else
            token = Token:new(nil, EOF)
        end
    end

    self.pos = self.pos + 1
    return token
end

function Lexer:num()
    input = self.input:sub(self.pos, self.pos)
    if (tonumber(input)) then
        digits = ""
        while true do
            newToken = self:getNextToken()
            if (newToken.type ~= INTEGER) then
                break
            end
            digits = digits .. tostring(newToken.value)
        end
        self.pos = self.pos - 1
        return Token:new(tonumber(digits), INTEGER)
    elseif (input == '(') then
        self.pos = self.pos + 1
        sum = self:expr()
        self.pos = self.pos + 1
        return Token:new(sum, INTEGER)
    elseif (input == ')') then
        return Token:new(nil, EOF)
    end
end

function Lexer:getNewToken()
    input = self.input:sub(self.pos, self.pos)
    if (tonumber(input) or input == '(' or input == ')') then
        return self:num()
    else
        return self:getNextToken()
    end
end

function Lexer:term()
    sum = self:getNewToken().value
    while true do
        sign = self:getNewToken()
        if sign.type ~= MUL and sign.type ~= DIV then
            self.pos = self.pos - 1
            break
        end
        if (sign.type == MUL) then
            sum = sum * self:getNewToken().value
        elseif (sign.type == DIV) then
            sum = sum / self:getNewToken().value
        end
    end
    return sum
end

function Lexer:expr()
    sum = self:term()
    while true do
        operation = self:getNewToken()
        if operation.type ~= ADD and operation.type ~= MIN then
            break
        end
        if (operation.type == ADD) then
            sum = sum + self:term()
        elseif (operation.type == MIN) then
            sum = sum - self:term()
        end
    end
    return sum
end

while true do
    input = io.read("*l")
    lexer = Lexer:new(input)
    print(lexer:expr())
end