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
    if (self.CurrentToken ~= self.Tokens.START) then
        error("ERROR: PROGRAM MUST START WITH START!")
    end
    return self:Statements()
end

function CParser:Statements()
    local Statements = {}
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.LBRACES) then
            self:SetNextToken()
        end
        Statements:push(self:Statements())
        -- This is where we get ;, }, {, FINISH, etc
        self:SetNextToken()
        if (self.CurrentToken.Type ~= self.Tokens.FINAL or self.CurrentToken.Type ~= self.Tokens.RBRACES) then
            break
        else
            self:SetNextToken(self.PastToken)
            self:SemicolonTest()
        end
    end
end

function CParser:Statement()
    return ({
        [self.Tokens.NUM_TYPE or self.Tokens.STR_TYPE or self.Tokens.BOOL_TYPE or self.Tokens.VAR] = function()
            return self:Assign()
        end,
        [self.Tokens.IF] = function()
            return self:IfElse()
        end,
        [self.Tokens.WHILE] = function()
            return self:While()
        end,
        [self.Tokens.FOR] = function()
            return self:For()
        end,
        [self.Tokens.PRINT] = function()
            return self:Print()
        end,
        [nil] = function()
            return nil
        end
    })[self.CurrentToken]
end

function CParser:Assign()
    if (self.CurrentToken.Value == self.Tokens.VAR) then
        self:SetNextToken()
        return CAST.CBinaryNode:new(self.CurrentToken, self.PastToken, self:Expr())
    else
        local Type = self.CurrentToken
        self:SetNextToken()
        self:SetNextToken()
        return CAST.CBinaryNode:new(CAST.CUnaryNode:new(Type, self.PastToken), self.CurrentToken, self:Expr())
    end
end

function CParser:IfElse()
    local If = self.CurrentToken
    local Condition = self:Condition()
    local FirstBranch = self:Statements()
    self:SetNextToken()
    if (self.CurrentToken.Token == self.Tokens.ELSE) then
        return CAST.CTernaryNode(If, Condition, FirstBranch, self:Statements())
    else
        return CAST.CTernaryNode(If, Condition, FirstBranch, nil)
    end
end

function CParser:Condition()
    local Expr1 = self:Expr()
    self:SetNextToken()
    return CAST.CBinaryNode:new(Expr1, self.CurrentToken, self:Expr())
end

function CParser:While()
    return CAST.CTernaryNode(self.CurrentToken, self:Condition(), self:Statements())
end

function CParser:For()
    local For = self.CurrentToken
    local Assign = self:Assign()
    self:SemicolonTest()
    local Condition = self:Condition()
    self:SetNextToken()
    self:SemicolonTest()
    local Expr = self:Expr()
    self:SetNextToken()
    return CAST.CQuaternaryNode(For, Assign, Condition, Expr, self:Statements())
end

function CParser:Expr()
    local Node = self:Term()
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Value == self.Tokens.MUL or self.CurrentToken.Value == self.Tokens.DIV) then
            Node =  CAST.CBinaryNode:new(self.CurrentToken, Node, self:Term())
        else
            self:SetNextToken(self.PastToken)
            break
        end
    end
    return Node
end

function CParser:Term()
    local Node = self:Value()
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Value == self.Tokens.ADD or self.CurrentToken.Value == self.Tokens.MIN) then
            Node =  CAST.CBinaryNode:new(self.CurrentToken, Node, self:Value())
        else
            self:SetNextToken(self.PastToken)
            break
        end
    end
    return Node
end

function CParser:Value()
    self:SetNextToken()
    Cases =
    {
        [self.Tokens.NUM or self.Tokens.STR or self.Tokens.BOOL or self.Tokens.VAR] = function ()
            return CAST.CNode(self.CurrentToken)
        end,
        [self.Tokens.ADD or self.Tokens.MIN] = function()
            return CAST.CUnaryNode(self,CurrentToken, self:Value())
        end,
        [self.Tokens.LPAREN] = function()
            return self:expr()
        end
    }
end

function CParser:Print()
    return CAST.CUnaryNode:new(self.CurrentToken, self:Expr())
end

function CParser:SetNextToken(Token)
    self.PastToken = self.CurrentToken
    if (Token ~= nil) then
        self.CurrentToken = Token
    else
        self.CurrentToken = self.Lexer:GetNextToken()
    end
end

function CParser:SemicolonTest()
    self:SetNextToken()
    if (self.CurrentToken.Type ~= self.Tokens.SEMI) then
        error("ERROR: SEMICOLON EXCEPTED")
    end
end

return { CParser }