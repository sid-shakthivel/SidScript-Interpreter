INTEGER, ADD, MIN, MUL, DIV, EOF, LPAREN, RPAREN = "INTEGER", "ADD", "MIN", "MUL", "DIV", "EOF", "LPAREN", "RPAREN"

CTreeNode = { Token, LeftNode, RightNode }

function CTreeNode:new(token)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = token
    self.__index = self
    return NewNode
end

function CTreeNode:SetLeftNode(LeftNode)
    self.LeftNode = LeftNode
end

function CTreeNode:SetRightNode(RightNode)
    self.RightNode = RightNode
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
    Digits = ""
    repeat
        Digit = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
        Digits = Digits .. tostring(Digit)
        self.CurrentPosition = self.CurrentPosition + 1
    until tonumber(Digit) ~= true
    self.CurrentPosition = self.CurrentPosition - 1
    return tonumber(Digits)
end

function CLexer:GetNextToken()
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
        ['('] = function()
            return CToken:new('(', LPAREN)
        end,
        [')'] = function ()
            return CToken:new(')', RPAREN)
        end
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
    Term = self:term()
    local Node = Term
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == ADD) then
            Node = CTreeNode:new(self.CurrentToken)
            Node:SetLeftNode(Term)
            Node:SetRightNode(self:term())
        elseif (self.CurrentToken.Type == MIN) then
            Node = CTreeNode:new(self.CurrentToken)
            Node:SetLeftNode(Term)
            Node:SetRightNode(self:term())
        else
            break
        end
    end
    return Node
end

function CParser:term()
    Factor = self:factor()
    local Node = Factor
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == MUL) then
            Node = CTreeNode:new(self.CurrentToken)
            Node:SetLeftNode(Factor)
            Node:SetRightNode(self:factor())
        elseif (self.CurrentToken.Type == DIV) then
            Node = CTreeNode:new(self.CurrentToken)
            Node:SetLeftNode(Factor)
            Node:SetRightNode(self:factor())
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
        return CTreeNode:new(self.CurrentToken)
    elseif (self.CurrentToken.Type == LPAREN) then
        return self:expr()
    end
end

CInterpreter = { Lexer, Parser }

function CInterpreter:new()
    NewInterpreter = {}
    setmetatable(NewInterpreter, self)
    NewInterpreter.Lexer = CLexer:new("(3+5)*4")
    NewInterpreter.Parser = CParser:new(NewInterpreter.Lexer)
    self.__index = self
    return NewInterpreter
end

function CInterpreter:compute()
    root = interpreter.Parser:expr()
    print(self:calculate(root))
end

function CInterpreter:calculate(CurrentNode)
    if (CurrentNode.Token.Type == ADD) then
        return self:calculate(CurrentNode.LeftNode) + self:calculate(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == MIN) then
        return self:calculate(CurrentNode.LeftNode) - self:calculate(CurrentNode.RightNode)
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
interpreter:compute()
