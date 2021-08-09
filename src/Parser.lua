local CAST = require("src.AST")

CParser = { Lexer, CurrentToken, Tokens, LastToken }

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
        error("ERROR: PROGRAM MUST START WITH START!")
    end
    local Statements = self:Statements()
    return Statements
end

function CParser:Statements()
    local Statements = {}
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.FINISH) then
            break
        end
        if (self.CurrentToken.Type == self.Tokens.RBRACE) then
            break
        end
        if (self.CurrentToken.Type == self.Tokens.LBRACE) then
            self:SetNextToken()
        end
        table.insert(Statements, self:Statement())
        if (self.CurrentToken.Type == self.Tokens.RBRACE) then
            ;
        elseif (self.CurrentToken.Type == self.Tokens.FINISH) then
            break
        else
            self:SemicolonTest()
        end
    end
    return Statements
end

function CParser:Statement()
    return ({
        [self.Tokens.NUM_TYPE] = function()
            self:SetNextToken()
            if (self.CurrentToken.Type == self.Tokens.FUNC) then
                self:SetNextToken(self.LastToken)
                return self:FunctionDeclaration()
            else
                self:SetNextToken(self.LastToken)
                return self:Assign()
            end
        end,
        [self.Tokens.STR_TYPE ] = function()
            self:SetNextToken()
            if (self.CurrentToken.Type == self.Tokens.FUNC) then
                self:SetNextToken(self.LastToken)
                return self:FunctionDeclaration()
            else
                self:SetNextToken(self.LastToken)
                return self:Assign()
            end
        end,
        [self.Tokens.BOOL_TYPE] = function()
            self:SetNextToken()
            if (self.CurrentToken.Type == self.Tokens.FUNC) then
                self:SetNextToken(self.LastToken)
                return self:FunctionDeclaration()
            else
                self:SetNextToken(self.LastToken)
                return self:Assign()
            end
        end,
        [self.Tokens.VOID_TYPE] = function()
            self:SetNextToken()
            if (self.CurrentToken.Type == self.Tokens.FUNC) then
                self:SetNextToken(self.LastToken)
                return self:FunctionDeclaration()
            else
                self:SetNextToken(self.LastToken)
                return self:Assign()
            end
        end,
        [self.Tokens.VAR] = function()
            self:SetNextToken()
            if (self.CurrentToken.Type == self.Tokens.LPAREN) then
                self:SetNextToken(self.LastToken)
                return self:FunctionCall()
            else
                self:SetNextToken(self.LastToken)
                return self:Assign()
            end
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
        [self.Tokens.ADD] = function()
            return self:Expr()
        end,
    })[self.CurrentToken.Type]()
end

function CParser:FunctionDeclaration()
    local FuncType = self.CurrentToken
    self:SetNextToken()
    local Func = self.CurrentToken
    self:SetNextToken()
    local FuncName = self.CurrentToken
    local Parameters = self:FunctionParameters()
    self:SetNextToken()
    return CAST.CQuaternaryNode:new(Func, Parameters, CAST.CNode:new(FuncName), CAST.CNode:new(FuncType),self:Statements())
end

function CParser:FunctionParameters()
    local Parameters = {}
    self:SetNextToken()
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.RPAREN) then
            break
        elseif (self.CurrentToken.Type == self.Tokens.NUM_TYPE) then
            local VarType = self.CurrentToken
            self:SetNextToken()
            table.insert(Parameters, CAST.CUnaryNode:new(VarType, CAST.CNode:new(self.CurrentToken)))
        elseif (self.CurrentToken.Type == self.Tokens.COMMA) then
            self:SetNextToken()
        elseif (self.CurrentToken.Type == self.Tokens.VAR) then
            table.insert(Parameters, CAST.CNode:new(self.CurrentToken))
        end
    end
    return Parameters
end

function CParser:FunctionCall()
    local FuncName = self.CurrentToken
    local Parameters = self:FunctionParameters()
    return CAST.CBinaryNode:new({ Value = "call", Type = self.Tokens.CALL }, CAST.CNode:new(FuncName), Parameters)
end

function CParser:Assign()
    if (self.CurrentToken.Type == self.Tokens.VAR) then
        self:SetNextToken()
        return CAST.CBinaryNode:new(self.CurrentToken, CAST.CNode:new(self.LastToken), self:Expr())
    else
        local Type = self.CurrentToken
        self:SetNextToken()
        self:SetNextToken()
        return CAST.CBinaryNode:new(self.CurrentToken, CAST.CUnaryNode:new(Type, CAST.CNode:new(self.LastToken)), self:Expr())
    end
end

function CParser:IfElse()
    local If = self.CurrentToken
    local Condition = self:Condition()
    local FirstBranch = self:Statements()
    self:SetNextToken()
    if (self.CurrentToken.Token == self.Tokens.ELSE) then
        return CAST.CTernaryNode:new(If, FirstBranch, Condition , self:Statements())
    else
        self:SetNextToken(self.LastToken)
        return CAST.CTernaryNode:new(If, FirstBranch , Condition, nil)
    end
end

function CParser:Condition()
    local Expr1 = self:Expr()
    self:SetNextToken()
    return CAST.CBinaryNode:new(self.CurrentToken, Expr1, self:Expr())
end

function CParser:While()
    local While = self.CurrentToken
    local Condition = self:Condition()
    local Statements = self:Statements()
    return CAST.CBinaryNode:new(While, Condition, Statements)
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
        if (self.CurrentToken.Type == self.Tokens.ADD or self.CurrentToken.Type == self.Tokens.ADD) then
            Node =  CAST.CBinaryNode:new(self.CurrentToken, Node, self:Term())
        else
            self:SetNextToken(self.LastToken)
            break
        end
    end
    return Node
end

function CParser:Term()
    local Node = self:Value()
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.MUL or self.CurrentToken.Type == self.Tokens.DIV) then
            Node =  CAST.CBinaryNode:new(self.CurrentToken, Node, self:Value())
        else
            self:SetNextToken(self.LastToken)
            break
        end
    end
    return Node
end

function CParser:Value()
    self:SetNextToken()
    return ({
        [self.Tokens.STR] = function ()
            return CAST.CNode:new(self.CurrentToken)
        end,
        [self.Tokens.NUM] = function()
            return CAST.CNode:new(self.CurrentToken)
        end,
        [self.Tokens.BOOL] = function()
            return CAST.CNode:new(self.CurrentToken)
        end,
        [self.Tokens.VAR] = function()
            return CAST.CNode:new(self.CurrentToken)
        end,
        [self.Tokens.ADD or self.Tokens.MIN] = function()
            return CAST.CUnaryNode:new(self,CurrentToken, self:Value())
        end,
        [self.Tokens.LPAREN] = function()
            return self:expr()
        end,
    })[self.CurrentToken.Type]()
end

function CParser:Print()
    return CAST.CUnaryNode:new(self.CurrentToken, self:Expr())
end

function CParser:SetNextToken(Token)
    self.LastToken = self.CurrentToken
    if (Token ~= nil) then
        self.CurrentToken = Token
        self.Lexer:SetLastToken()
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