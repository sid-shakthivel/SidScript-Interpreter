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
    if (self.CurrentToken.Type ~= self.Tokens.START) then
        error("ERROR: PROGRAM MUST START WITH START KEYWORD")
    else
        return self:Statements()
    end
end

function CParser:Statements()
    local Statements = {}
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.LBRACES) then
            self:SetNextToken()
        end
        table.insert(Statements, (self:Statement()))
        if (self.CurrentToken.Type == self.Tokens.SEMI) then
            ;
        elseif (self.CurrentToken.Type == self.Tokens.FINISH) then
            break
        elseif (self.CurrentToken.Type == self.Tokens.RBRACES) then
            break
        end
    end
    return Statements
end

function CParser:Statement()
    if (self.CurrentToken.Type == self.Tokens.VAR or self.CurrentToken.Type == self.Tokens.NUM_TYPE or self.CurrentToken.Type == self.Tokens.STR_TYPE or self.CurrentToken.Type == self.Tokens.BOOL_TYPE) then
        return self:Assignment()
    elseif (self.CurrentToken.Type == self.Tokens.IF) then
        return self:IfElseStatement()
    else
        return nil
    end
end

function CParser:IfElseStatement()
    local If = self.CurrentToken
    local Conditional = self:Conditional()
    self:SetNextToken()
    local Branch = self:Statements()
    self:SetNextToken()
    if (self.CurrentToken.Type == self.Tokens.ELSE) then
        self:SetNextToken()
        return CAST.CTernaryNode:new(If, Branch, Conditional, self:Statements())
    else
        return CAST.CTernaryNode:new(If, Condition, Branch, nil)
    end
end

function CParser:Conditional()
    self:SetNextToken()
    local Condition = self:Value()
    self:SetNextToken()
    return CAST.CBinaryNode:new(self.CurrentToken, Condition, self:Value())
end

function CParser:Assignment()
    local Node = self:Variable()
    self:SetNextToken()
    local Operation = self.CurrentToken
    local Test = self:Value()
    Node = CAST.CBinaryNode:new(Operation, Node, Test)
    return Node
end

function CParser:Value()
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
            self.Lexer.CurrentPosition = self.Lexer.CurrentPosition - 1
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
        local Operator = CAST.CUnaryNode:new(self.CurrentToken, self:Factor())
        return Operator
    else
        return self:Variable()
    end
end

function CParser:SetNextToken()
    self.CurrentToken = self.Lexer:GetNextToken()
end

return { CParser }