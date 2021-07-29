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

CAssignmentNode = { Token, Variable, Expr }

function CAssignmentNode:new(Token, Variable, Expr)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = Token
    NewNode.Variable = Variable
    NewNode.Expr = Expr
    self.__index = self
    return NewNode
end

CProgramNode = { Children }

function CProgramNode:new()
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Children = {}
    self.__index = self
    return NewNode
end

CNode = { Token }

function CNode:new(Token)
    NewNode = {}
    setmetatable(CNode, self)
    NewNode.Token = Token
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

VariableTable = {}

function CLexer:GetInteger()
    local Digits = ""
    while true do
        local Digit = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
        if (tonumber(Digit)) then
            Digits = Digits .. Digit
        else
            break
        end
        self.CurrentPosition = self.CurrentPosition + 1
    end
    self.CurrentPosition = self.CurrentPosition - 1
    return tonumber(Digits)
end

function CLexer:GetNextToken()
    local Character = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
    local Token

    if (Character == ' ') then
        self.CurrentPosition = self.CurrentPosition + 1
        Character = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
    end

    case = {
        ['+'] = function()
            return CToken:new('+', Tokens.ADD)
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
            local Result = string.gsub(self.Input:sub(OldPosition, NextSpace-1), ";", "")
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

CParser = { Lexer, CurrentToken }

function CParser:new(lexer)
    NewParser = {}
    setmetatable(NewParser, self)
    NewParser.Lexer = lexer
    self.__index = self
    return NewParser
end

function CParser:Program()
    self:SetNextToken()
    return self:Statements()
end

function CParser:Statements()
    Statements = {}
    while true do
        table.insert(Statements, (self:Statement()))
        if (self.CurrentToken.Type ~= Tokens.SEMI) then
            break
        end
    end
    return Statements
end

function CParser:Statement()
    self:SetNextToken()
    if (self.CurrentToken.Type == Tokens.VAR) then
        return self:Assignment()
    end
end

function CParser:Assignment()
    local Node = self:var()
    self:SetNextToken()
    Node = CAssignmentNode:new(self.CurrentToken, Node, self:expr())
    return Node
end

function CParser:expr()
    local Node = self:term()
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == Tokens.ADD or self.CurrentToken.Type == Tokens.MIN) then
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
        if (self.CurrentToken.Type == Tokens.MUL or self.CurrentToken.Type == Tokens.DIV) then
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
    if (self.CurrentToken.Type == Tokens.INTEGER) then
        return CNode:new(self.CurrentToken)
    elseif (self.CurrentToken.Type == Tokens.LPAREN) then
        return self:expr()
    elseif (self.CurrentToken.Type == Tokens.ADD or self.CurrentToken.Type == Tokens.MIN) then
        local Operator = CUnaryNode:new(self.CurrentToken, self:factor())
        return Operator
    else
        return self:var()
    end
end

function CParser:var()
    return CNode:new(self.CurrentToken)
end

function CParser:SetNextToken()
    self.CurrentToken = self.Lexer:GetNextToken()
end

CInterpreter = { Lexer, Parser }

function CInterpreter:new(LexerInput)
    NewInterpreter = {}
    setmetatable(NewInterpreter, self)
    NewInterpreter.Lexer = CLexer:new(LexerInput)
    NewInterpreter.Parser = CParser:new(NewInterpreter.Lexer)
    self.__index = self
    return NewInterpreter
end

function CInterpreter:Interpret(CurrentNode)
    if (CurrentNode == nil or CurrentNode.Token == nil) then
        return 0
    elseif (CurrentNode.Token.Type == Tokens.ASSIGN) then
        VariableTable[CurrentNode.Variable.Token.Value] = self:Interpret(CurrentNode.Expr)
        return 0
    elseif (CurrentNode.Token.Type == Tokens.ADD) then
        if (CurrentNode.NextNode) then
            return self:Interpret(CurrentNode.NextNode)
        else
            return self:Interpret(CurrentNode.LeftNode) + self:Interpret(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == Tokens.MIN) then
        if (CurrentNode.NextNode) then
            return -self:Interpret(CurrentNode.NextNode)
        else
            return self:Interpret(CurrentNode.LeftNode) - self:Interpret(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == Tokens.MUL) then
        return self:Interpret(CurrentNode.LeftNode) * self:Interpret(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == Tokens.DIV) then
        return self:Interpret(CurrentNode.LeftNode) / self:Interpret(CurrentNode.RightNode)
    elseif (tonumber(CurrentNode.Token.Value)) then
        return tonumber(CurrentNode.Token.Value)
    elseif (CurrentNode.Token.Type == Tokens.VAR) then
        return VariableTable[CurrentNode.Token.Value]
    end
end

function CInterpreter:Execute()
    Root = self.Parser:Program()
    for i = 1, #Root do
        self:Interpret(Root[i])
    end

    print(VariableTable["test"])
    print(VariableTable["variable"])
    print(VariableTable["jim"])
end

interpreter = CInterpreter:new("START test = 4*5; variable = 31; jim = variable + test; FINISH")
interpreter:Execute()

-- test = (4+5)*4; variable = 45;