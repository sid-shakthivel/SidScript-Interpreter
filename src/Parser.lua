local CAST = require("src.AST")
local Error = require("src.Error")

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
    local Statements = self:Statements(false)
    return Statements
end

function CParser:Statements(IsExpectingRightBrace)
    local Statements = {}
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.RBRACE) then
            IsExpectingRightBrace = false
            break
        end
        if (self.CurrentToken.Type == self.Tokens.EOF) then
            if (IsExpectingRightBrace == false) then
                break
            else
                Error:Error("PARSER ERROR: EXPECTED RIGHT BRACE BEFORE " .. self.CurrentToken.Type)
            end
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
    local Type = self.CurrentToken.Type
    if (Type == self.Tokens.NUM_TYPE or Type == self.Tokens.STR_TYPE or Type == self.Tokens.BOOL_TYPE or Type == self.Tokens.VOID_TYPE) then
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.FUNC) then
            self:SetNextToken(self.LastToken)
            return self:FunctionDeclaration()
        else
            self:SetNextToken(self.LastToken)
            return self:Assign()
        end
    elseif (Type == self.Tokens.VAR) then
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.LPAREN) then
            self:SetNextToken(self.LastToken)
            return self:FunctionCall()
        else
            self:SetNextToken(self.LastToken)
            return self:Assign()
        end
    elseif (Type == self.Tokens.IF) then
        return self:IfElse()
    elseif (Type == self.Tokens.WHILE) then
        return self:While()
    elseif (Type == self.Tokens.FOR) then
        return self:For()
    elseif (Type == self.Tokens.PRINT) then
        return self:Print()
    elseif (Type == self.Tokens.ADD) then
        return self:Expr()
    else
        Error:Error("PARSER ERROR: INSTRUCTION " .. self.CurrentToken.Value .. " NOT DEFINED")
    end
end

function CParser:FunctionDeclaration()
    local FuncType = self.CurrentToken
    self:SetNextToken()
    local Func = self.CurrentToken
    self:SetNextToken()
    local FuncName = self.CurrentToken
    local Parameters = self:FunctionParameters()
    self:LeftBraceTest()
    return CAST.CQuaternaryNode:new(Func, Parameters, CAST.CNode:new(FuncName), CAST.CNode:new(FuncType),self:Statements(true))
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
    self:LeftBraceTest()
    local FirstBranch = self:Statements(true)
    self:SetNextToken()
    if (self.CurrentToken.Type == self.Tokens.ELSE) then
        self:LeftBraceTest()
        return CAST.CTernaryNode:new(If, FirstBranch, Condition , self:Statements(true))
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
    self:LeftBraceTest()
    local Statements = self:Statements(true)
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
    return CAST.CQuaternaryNode(For, Assign, Condition, Expr, self:Statements(true))
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
    local Cases = {
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
    }
    if (Cases[self.CurrentToken.Type]) then
        return Cases[self.CurrentToken.Type]()
    else
        Error:Error("PARSER ERROR: INVALID SYNTAX " .. self.CurrentToken.Value)
    end
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
        Error:Error("PARSER ERROR: SEMICOLON EXCEPTED AFTER " .. self.CurrentToken.Value)
    end
end

function CParser:LeftBraceTest()
    self:SetNextToken()
    if (self.CurrentToken.Type ~= self.Tokens.LBRACE) then
        Error:Error("PARSER ERROR: EXPECTED LEFT BRACE BEFORE " .. self.CurrentToken.Value)
    end
end

return { CParser }