INTEGER, ADD, MIN, MUL, DIV, EOF = "INTEGER", "ADD", "MIN", "MUL", "DIV", "EOF"

TreeNode = { Value, LeftNode, RightNode }

function TreeNode:new(value)
    setmetatable({}, TreeNode)
    self.Value = value
    return self
end

CToken = { Value, Type }

function CToken:new(value, type)
    setmetatable({}, CToken)
    self.Value = value
    self.Type = type
    return self
end

Lexer = { CurrentPosition, Input }

function Lexer:new(input)
    setmetatable({ }, Lexer)
    self.Input = input
    self.CurrentPosition = 1
    return self
end

function Lexer:GetInteger()
    Digits = ""
    repeat
        Digit = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
        Digits = Digits .. tostring(Digit)
        self.CurrentPosition = self.CurrentPosition + 1
    until tonumber(Digit) ~= true
    self.CurrentPosition = self.CurrentPosition - 1
    return tonumber(Digits)
end

function Lexer:GetNextToken()
    Character = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
    Token = nil

    if (Character == ' ') then
        self.CurrentPosition = self.CurrentPosition + 1
    end

    case = {
        ['+'] = function()
            return CToken:new('+', ADD)
        end,
        ['-'] = function()
            return CToken:new('-', MIN)
        end,
        ['*'] = function()
            return CToken:new('*', MUL)
        end,
        ['/'] = function()
            return CToken:new('/', DIV)
        end,
    }

    if (tonumber(Character)) then
        Token = CToken:new(self:GetInteger(), INTEGER)
    else
        if (case[Character]) then
            Token = case[Character]()
        else
            Token = CToken:new(nil, EOF)
        end
    end

    self.CurrentPosition = self.CurrentPosition + 1
    return Token
end

Parser = { Lexer, CurrentToken }

function Parser:new(lexer)
    setmetatable({ }, Parser)
    self.Lexer = lexer
    return self
end

function Parser:SetNextToken()
    self.CurrentToken = self.Lexer:GetNextToken()
end

function Parser:expr()
    Term = self:term()
    Sum = Term
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == ADD) then
            Sum = Factor + self:term()
        elseif (self.CurrentToken.Type == MIN) then
            Sum = Factor - self:term()
        else
            break
        end
    end
    return Sum
end

function Parser:term()
    Factor = self:factor()
    Sum = Factor
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == MUL) then
            Sum = Factor * self:factor()
        elseif (self.CurrentToken.Type == DIV) then
            Sum = Factor / self:factor()
        else
            self.Lexer.CurrentPosition = self.Lexer.CurrentPosition - 1
            break
        end
    end
    return Sum
end

function Parser:factor()
    self:SetNextToken()
    return self.CurrentToken.Value
end

Interpreter = { Lexer, Parser }

function Interpreter:new()
    setmetatable({ }, Interpreter)
    self.Lexer = Lexer:new("3+5")
    self.Parser = Parser:new(self.Lexer)
    return self
end

interpreter = Interpreter:new()
print(interpreter.Parser:expr())