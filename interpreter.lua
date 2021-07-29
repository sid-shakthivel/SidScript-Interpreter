Tokens = {
    INTEGER = "INTEGER",
    ADD = "ADD",
    MIN = "MIN",
    DIV = "DIV",
    MUL = "MUL",
    EOF = "EOF",
    LPAREN = "LPAREN",
    RPAREN = "RPAREN",
    START = "START",
    FINISH = "FINISH",
    DOT = "DOT",
    ASSIGN = "ASSIGN",
    VAR = "VAR",
    SEMI = "SEMI"
}

CBinaryNode = { Token, LeftNode, RightNode }

function CBinaryNode:new(Token, LeftNode, RightNode)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = Token
    NewNode.LeftNode = LeftNode or nil
    NewNode.RightNode = RightNode or nil
    self.__index = self
    return NewNode
end

CUnaryNode = { Token, NextNode }

function CUnaryNode:new(Token, NextNode)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = Token
    NewNode.NextNode = NextNode
    self.__index = self
    return NewNode
end

CToken = { Value, Type }

function CToken:new(value, type)
    NewToken = {}
    setmetatable({}, self)
    NewToken.Value = value
    NewToken.Type = type
    self.__index = self
    return NewToken
end

CLexer = { CurrentPosition, Input }

function CLexer:new(input)
    NewLexer = {}
    setmetatable(NewLexer, self)
    NewLexer.Input = input
    NewLexer.CurrentPosition = 1
    self.__index = self
    return NewLexer
end

function CLexer:GetInteger()
    local Digits = ""
    repeat
        Digit = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
        Digits = Digits .. tostring(Digit)
        self.CurrentPosition = self.CurrentPosition + 1
    until tonumber(Digit) ~= true
    self.CurrentPosition = self.CurrentPosition - 1
    return tonumber(Digits)
end

function CLexer:GetNextToken()
    local Character = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
    local Token = nil

    if (Character == ' ') then
        self.CurrentPosition = self.CurrentPosition + 1
        Character = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
    end

    case = {
        ['+'] = function()
            return CToken:new('+', Tokens.Add)
        end,
        ['-'] = function()
            return CToken:new('-', Tokens.MIN)
        end,
        ['*'] = function()
            return CToken:new('*', Tokens.MUL)
        end,
        ['/'] = function()
            return CToken:new('/', Tokens.DIV)
        end,
        ['('] = function()
            return CToken:new('(', Tokens.LPAREN)
        end,
        [')'] = function()
            return CToken:new(')', Tokens.RPAREN)
        end,
        ['.'] = function()
            return CToken:new('.', Tokens.DOT)
        end,
        [';'] = function()
            return CToken:new(';', Tokens.SEMI)
        end,
        ['='] = function()
            return CToken:new('=', Tokens.ASSIGN)
        end
    }

    if (tonumber(Character)) then
        Token = CToken:new(self:GetInteger(), Tokens.INTEGER)
    else
        if (case[Character]) then
            Token = case[Character]()
        else
            local OldPosition = self.CurrentPosition
            local NextSpace = string.find(self.Input, " ", self.CurrentPosition) or #self.Input + 1
            local Result = self.Input:sub(OldPosition, NextSpace-1)
            if Result == "START" then
                Token = CToken:new(Result, Tokens.START)
            elseif Result == "FINISH" then
                Token = CToken:new(Result, Tokens.FINISH)
            else
                Token = CToken:new(Result, Tokens.VAR)
            end
            self.CurrentPosition = NextSpace
        end
    end

    self.CurrentPosition = self.CurrentPosition + 1
    return Token
end

lexer = CLexer:new("START a = 2; FINISH")
print(lexer:GetNextToken().Type)
print(lexer:GetNextToken().Type)
print(lexer:GetNextToken().Type)
print(lexer:GetNextToken().Type)
print(lexer:GetNextToken().Type)
print(lexer:GetNextToken().Type)

CParser = { Lexer, CurrentToken }

function CParser:new(lexer)
    NewParser = {}
    setmetatable(NewParser, self)
    NewParser.Lexer = lexer
    self.__index = self
    return NewParser
end

function CParser:SetNextToken()
    self.CurrentToken = self.Lexer:GetNextToken()
end

function CParser:expr()
    local Node = self:term()
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == ADD or self.CurrentToken.Type == MIN) then
            Node = CBinaryNode:new(self.CurrentToken, Node, self:term())
        else
            break
        end
    end
    return Node
end

function CParser:term()
    local Node = self:factor()
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == MUL or self.CurrentToken.Type == DIV) then
            Node = CBinaryNode:new(self.CurrentToken, Node, self:factor())
        else
            self.Lexer.CurrentPosition = self.Lexer.CurrentPosition - 1
            break
        end
    end
    return Node
end

function CParser:factor()
    self:SetNextToken()
    if (self.CurrentToken.Type == INTEGER) then
        return CUnaryNode:new(self.CurrentToken)
    elseif (self.CurrentToken.Type == LPAREN) then
        return self:expr()
    elseif (self.CurrentToken.Type == ADD or self.CurrentToken.Type == MIN) then
        local Operator = CUnaryNode:new(self.CurrentToken, self:factor())
        return Operator
    end
end

CInterpreter = { Lexer, Parser }

function CInterpreter:new()
    NewInterpreter = {}
    setmetatable(NewInterpreter, self)
    NewInterpreter.Lexer = CLexer:new("5 - - - + - (3 + 4) - +2")
    NewInterpreter.Parser = CParser:new(NewInterpreter.Lexer)
    self.__index = self
    return NewInterpreter
end

function CInterpreter:compute()
--
end

function CInterpreter:calculate(CurrentNode)
    if (CurrentNode == nil or CurrentNode.Token == nil) then
        return 0
    elseif (CurrentNode.Token.Type == ADD) then
        if (CurrentNode.NextNode) then
            return self:calculate(CurrentNode.NextNode)
        else
            return self:calculate(CurrentNode.LeftNode) + self:calculate(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == MIN) then
        if (CurrentNode.NextNode) then
            return -self:calculate(CurrentNode.NextNode)
        else
            return self:calculate(CurrentNode.LeftNode) - self:calculate(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == MUL) then
        return self:calculate(CurrentNode.LeftNode) * self:calculate(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == DIV) then
        return self:calculate(CurrentNode.LeftNode) / self:calculate(CurrentNode.RightNode)
    elseif (tonumber(CurrentNode.Token.Value)) then
        return tonumber(CurrentNode.Token.Value)
    else
        return 0
    end
end

interpreter = CInterpreter:new()
