local CAST = require("src.AST")

CParser = { Lexer, CurrentToken, Tokens }

function CParser:new(Lexer)
    NewParser = {}
    setmetatable(NewParser, self)
    NewParser.Lexer = Lexer
    NewParser.Tokens = NewParser.Lexer.Tokens
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
        if (self.CurrentToken.Type ~= self.Tokens.SEMI) then
            break
        end
    end
    return Statements
end

function CParser:Statement()
    self:SetNextToken()
    if (self.CurrentToken.Type == self.Tokens.NUM_TYPE or self.CurrentToken.Type == self.Tokens.STR_TYPE or self.CurrentToken.Type == self.Tokens.BOOL_TYPE or self.CurrentToken.Type == self.Tokens.VAR) then
        return self:Assignment()
    end
end

function CParser:Assignment()
    local Node = self:Variable()
    self:SetNextToken()
    Node = CAST.CBinaryNode:new(self.CurrentToken, Node, self:Value())
    return Node
end

function CParser:Value()
    self:SetNextToken()
    if (self.CurrentToken.Type == self.Tokens.STR) then
        return CAST.CNode:new(self.CurrentToken)
    elseif (self.CurrentToken.Type == self.Tokens.BOOL) then
        return CAST.CNode:new(self.CurrentToken)
    else
        return self:Expr()
    end
end

function CParser:Variable()
    if (self.CurrentToken.Type == self.Tokens.NUM_TYPE or self.CurrentToken.Type == self.Tokens.STR_TYPE or self.CurrentToken.Type == self.Tokens.BOOL_TYPE) then
        local OldToken = self.CurrentToken
        self:SetNextToken()
        return CAST.CUnaryNode:new(OldToken, self:Variable())
    else
        return CAST.CNode:new(self.CurrentToken)
    end
end

function CParser:Expr()
    local Node = self:Term()
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.ADD or self.CurrentToken.Type == self.Tokens.MIN) then
            Node = CAST.CBinaryNode:new(self.CurrentToken, Node, self:Term())
        else
            break
        end
    end
    return Node
end

function CParser:Term()
    local Node = self:Factor()
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.MUL or self.CurrentToken.Type == self.Tokens.DIV) then
            Node = CAST.CBinaryNode:new(self.CurrentToken, Node, self:Factor())
        else
            self.Lexer.CurrentPosition = self.Lexer.CurrentPosition - 1
            break
        end
    end
    return Node
end

function CParser:Factor()
    self:SetNextToken()
    if (self.CurrentToken.Type == self.Tokens.NUM) then
        return CAST.CNode:new(self.CurrentToken)
    elseif (self.CurrentToken.Type == self.Tokens.LPAREN) then
        return self:Expr()
    elseif (self.CurrentToken.Type == self.Tokens.ADD or self.CurrentToken.Type == self.Tokens.MIN) then
        local Operator = CAST.CUnaryNode:new(self.CurrentToken, self:factor())
        return Operator
    else
        return self:Variable()
    end
end

function CParser:SetNextToken()
    self.CurrentToken = self.Lexer:GetNextToken()
end

return { CParser }