local CAST = require("src.AST")

CParser = { Lexer, CurrentToken }

function CParser:new(Lexer)
    NewParser = {}
    setmetatable(NewParser, self)
    NewParser.Lexer = Lexer
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
        if (self.CurrentToken.Type ~= self.Lexer.Tokens.SEMI) then
            break
        end
    end
    return Statements
end

function CParser:Statement()
    self:SetNextToken()
    if (self.CurrentToken.Type == self.Lexer.Tokens.NUM or self.CurrentToken.Type == self.Lexer.Tokens.STR or self.CurrentToken.Type == self.Lexer.Tokens.BOOL or self.CurrentToken.Type == self.Lexer.Tokens.VAR) then
        return self:Assignment()
    end
end

function CParser:Assignment()
    local Node = self:var()
    self:SetNextToken()
    Node = CAST.CBinaryNode:new(self.CurrentToken, Node, self:expr())
    return Node
end

function CParser:expr()
    local Node = self:term()
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Lexer.Tokens.ADD or self.CurrentToken.Type == self.Lexer.Tokens.MIN) then
            Node = CAST.CBinaryNode:new(self.CurrentToken, Node, self:term())
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
        if (self.CurrentToken.Type == self.Lexer.Tokens.MUL or self.CurrentToken.Type == self.Lexer.Tokens.DIV) then
            Node = CAST.CBinaryNode:new(self.CurrentToken, Node, self:factor())
        else
            self.Lexer.CurrentPosition = self.Lexer.CurrentPosition - 1
            break
        end
    end
    return Node
end

function CParser:factor()
    self:SetNextToken()
    if (self.CurrentToken.Type == self.Lexer.Tokens.INTEGER) then
        return CAST.CNode:new(self.CurrentToken)
    elseif (self.CurrentToken.Type == self.Lexer.Tokens.LPAREN) then
        return self:expr()
    elseif (self.CurrentToken.Type == self.Lexer.Tokens.ADD or self.CurrentToken.Type == self.Lexer.Tokens.MIN) then
        local Operator = CAST.CUnaryNode:new(self.CurrentToken, self:factor())
        return Operator
    else
        return self:var()
    end
end

function CParser:var()
    if (self.CurrentToken.Type == self.Lexer.Tokens.NUM) then
        local OldToken = self.CurrentToken
        self:SetNextToken()
        return CAST.CUnaryNode:new(OldToken, self:var())
    else
        return CAST.CNode:new(self.CurrentToken)
    end
end

function CParser:SetNextToken()
    self.CurrentToken = self.Lexer:GetNextToken()
end

return { CParser }