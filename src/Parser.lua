local CAST = require("src.AST")

CParser = { Lexer, CurrentToken, Tokens, PastToken }

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
        else
            print(self.CurrentToken.Value)
            error("ERROR: SEMI COLON MUST FOLLOW EACH STATEMENT")
        end
    end
    return Statements
end

function CParser:Statement()
    if (self.CurrentToken.Type == self.Tokens.VAR or self.CurrentToken.Type == self.Tokens.NUM_TYPE or self.CurrentToken.Type == self.Tokens.STR_TYPE or self.CurrentToken.Type == self.Tokens.BOOL_TYPE) then
        return self:Assign()
    elseif (self.CurrentToken.Type == self.Tokens.IF) then
        return self:IfElse()
    elseif (self.CurrentToken.Type == self.Tokens.PRINT) then
        return self:Print()
    elseif (self.CurrentToken.Type == self.Tokens.WHILE) then
        return self:While()
    elseif (self.CurrentToken.Type == self.Tokens.FOR) then
        return self:For()
    else
        return nil
    end
end

function CParser:Print()
    local Print = self.CurrentToken
    local Test = self:Value()
    self:SetNextToken()
    return CAST.CUnaryNode:new(Print, Test)
end

function CParser:While()
    local While = self.CurrentToken
    local Condition = self:Condition()
    return CAST.CBinaryNode:new(While, Condition, self:Statements())
end

function CParser:For()
    local For = self.CurrentToken
    self:SetNextToken()
    local Variable = self:Assign()
    local Condition = self:Condition()
    self:SetNextToken()
    self:SetNextToken()
    local Increment = self:Expr()
    return CAST.CQuaternaryNode:new(For, Variable, Condition, Increment, self:Statements())
end

function CParser:IfElse()
    local If = self.CurrentToken
    local Condition = self:Condition()
    local Branch = self:Statements()
    self:SetNextToken()
    if (self.CurrentToken.Type == self.Tokens.ELSE) then
        self:SetNextToken()
        return CAST.CTernaryNode:new(If, Branch, Condition, self:Statements())
    else
        return CAST.CTernaryNode:new(If, Branch, Condition, nil)
    end
end

function CParser:Condition()
    local Condition = self:Value()
    self:SetNextToken()
    return CAST.CBinaryNode:new(self.CurrentToken, Condition, self:Value())
end

function CParser:Assign()
    local Node = self:Variable()
    self:SetNextToken()
    Node = CAST.CBinaryNode:new(self.CurrentToken, Node, self:Value())
    self:SetNextToken()
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

    --elseif (self.CurrentToken.Type == self.Tokens.VAR) then
    --return CAST.CNode:new(self.CurrentToken)
end

function CParser:Expr()
    local Node = self:Term()

    while true do
        self:SetNextToken()
        local Operation = self.CurrentToken
        if (self.CurrentToken.Type == self.Tokens.ADD or self.CurrentToken.Type == self.Tokens.MIN) then
            self:SetNextToken()
            Node = CAST.CBinaryNode:new(Operation, Node, self:Term())
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
        local Operation = self.CurrentToken
        if (self.CurrentToken.Type == self.Tokens.MUL or self.CurrentToken.Type == self.Tokens.DIV) then
            self:SetNextToken()
            Node = CAST.CBinaryNode:new(Operation, Node, self:Factor())
        else
            self.Lexer.CurrentPosition = self.Lexer.CurrentPosition - 1
            break
        end
    end
    return Node
end

function CParser:Factor()
    if (self.CurrentToken.Type == self.Tokens.NUM) then
        return CAST.CNode:new(self.CurrentToken)
    elseif (self.CurrentToken.Type == self.Tokens.LPAREN) then
        return self:Expr()
    elseif (self.CurrentToken.Type == self.Tokens.ADD or self.CurrentToken.Type == self.Tokens.MIN) then
        self:SetNextToken()
        local Operator = CAST.CUnaryNode:new(self.CurrentToken, self:Factor())
        return Operator
    else
    --    Must be a variable
        return self:Variable()
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

function CParser:SetNextToken()
    self.PastToken = self.CurrentToken
    self.CurrentToken = self.Lexer:GetNextToken()
end

return { CParser }