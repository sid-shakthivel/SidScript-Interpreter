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
    return self:Statements(false)
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
                Error:Error("PARSER ERROR: EXPECTED RIGHT BRACE ON LINE " .. self.CurrentToken.LineNumber)
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
    if (Type == self.Tokens.NUM_TYPE or Type == self.Tokens.STR_TYPE or Type == self.Tokens.BOOL_TYPE or Type == self.Tokens.VOID_TYPE or Type == self.Tokens.LIST_TYPE) then
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
    elseif (Type == self.Tokens.RETURN) then
        return self:Return()
    elseif (Type == self.Tokens.REMOVE) then
        return self:ListRemove()
    elseif (Type == self.Tokens.PUSH) then
        return self:ListPush()
    else
        Error:Error("PARSER ERROR: IDENTIFIER " .. self.CurrentToken.Value .. " NOT DEFINED ON LINE " .. self.CurrentToken.LineNumber)
    end
end

function CParser:Print()
    return CAST.CUnaryNode:new(self.CurrentToken, self:Expr())
end

function CParser:FunctionDeclaration()
    local FuncType = self.CurrentToken
    self:CheckSetNextToken(self.Tokens.FUNC)
    local Func = self.CurrentToken
    self:CheckSetNextToken(self.Tokens.VAR)
    local FuncName = self.CurrentToken
    local Parameters = self:Parameters(true)
    self:CheckSetNextToken(self.Tokens.LBRACE)
    return CAST.CQuaternaryNode:new(Func, Parameters, CAST.CNode:new(FuncName), CAST.CNode:new(FuncType),self:Statements(true))
end

function CParser:FunctionCall()
    local FuncName = self.CurrentToken
    local Parameters = self:Parameters(true)
    return CAST.CBinaryNode:new({ Value = "CALL", Type = self.Tokens.CALL }, CAST.CNode:new(FuncName), Parameters)
end

function CParser:Return()
    return CAST.CUnaryNode:new(self.CurrentToken, self:Expr())
end

function CParser:Assign()
    if (self.CurrentToken.Type == self.Tokens.VAR) then
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.ASSIGN) then
            return CAST.CBinaryNode:new(self.CurrentToken, CAST.CNode:new(self.LastToken), self:Expr())
        elseif (self.CurrentToken.Type == self.Tokens.LBRACKET) then
            self:SetNextToken(self.LastToken)
            local ListMember = self:ListMember()
            self:CheckSetNextToken(self.Tokens.ASSIGN)
            return CAST.CBinaryNode:new(self.CurrentToken, ListMember, self:Expr())
        else
            Error:Error("UNEXPECTED IDENTIFIER " .. self.CurrentToken.Value .. " ON LINE " .. self.CurrentToken.LineNumber)
        end
    else
        local Type = self.CurrentToken
        self:CheckSetNextToken(self.Tokens.VAR)
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.ASSIGN) then
            return CAST.CBinaryNode:new(self.CurrentToken, CAST.CUnaryNode:new(Type, CAST.CNode:new(self.LastToken)), self:Expr())
        elseif (self.CurrentToken.Type == self.Tokens.SEMI) then
            self:SetNextToken(self.LastToken)
            return CAST.CBinaryNode:new({ Type = self.Tokens.ASSIGN }, CAST.CUnaryNode:new(Type, CAST.CNode:new(self.CurrentToken)), nil)
        else
            Error:Error("UNEXPECTED IDENTIFIER " .. self.CurrentToken.Value .. " ON LINE " .. self.CurrentToken.LineNumber)
        end
    end
end

function CParser:IfElse()
    local If = self.CurrentToken
    local Condition = self:Condition()
    self:CheckSetNextToken(self.Tokens.LBRACE)
    local FirstBranch = self:Statements(true)
    self:SetNextToken()
    if (self.CurrentToken.Type == self.Tokens.ELSE) then
        self:CheckSetNextToken(self.Tokens.LBRACE)
        return CAST.CTernaryNode:new(If, FirstBranch, Condition , self:Statements(true))
    else
        self:SetNextToken(self.LastToken)
        return CAST.CTernaryNode:new(If, FirstBranch , Condition, nil)
    end
end

function CParser:While()
    local While = self.CurrentToken
    local Condition = self:Condition()
    self:CheckSetNextToken(self.Tokens.LBRACE)
    local Statements = self:Statements(true)
    return CAST.CBinaryNode:new(While, Condition, Statements)
end

function CParser:For()
    local For = self.CurrentToken
    self:SetNextToken()
    local Assign = self:Assign()
    self:SemicolonTest()
    local Condition = self:Condition()
    self:SemicolonTest()
    local Expr = self:Expr()
    self:CheckSetNextToken(self.Tokens.LBRACE)
    return CAST.CQuaternaryNode:new(For, Assign, Condition, Expr, self:Statements(true))
end

function CParser:Condition()
    local Expr1 = self:Expr()
    self:SetNextToken()
    if (self.CurrentToken.Type ~= self.Tokens.EQUALS and self.CurrentToken.Type ~= self.Tokens.LESSER and self.CurrentToken.Type ~= self.Tokens.GREATER) then
        Error:Error("PARSER ERROR: UNEXPECTED IDENTIFIER " .. self.CurrentToken.Value .. " ON LINE " .. self.CurrentToken.LineNumber)
    end
    return CAST.CBinaryNode:new(self.CurrentToken, Expr1, self:Expr())
end

function CParser:ListMember()
    local ListName = self.CurrentToken
    ListName.Type = self.Tokens.LIST
    self:CheckSetNextToken(self.Tokens.LBRACKET)
    --self:CheckSetNextToken(self.Tokens.NUM)
    self:SetNextToken()
    local Index = self.CurrentToken
    self:CheckSetNextToken(self.Tokens.RBRACKET)
    return CAST.CUnaryNode:new(ListName, CAST.CNode:new(Index))
end

function CParser:ListPush()
    local ListPush = self.CurrentToken
    self:CheckSetNextToken(self.Tokens.LPAREN)
    self:CheckSetNextToken(self.Tokens.VAR)
    local List = self.CurrentToken
    self:CheckSetNextToken(self.Tokens.COMMA)
    local NewListMember = self:Value()
    self:CheckSetNextToken(self.Tokens.RPAREN)
    return CAST.CBinaryNode:new(ListPush, CAST.CNode:new(List), NewListMember)
end

function CParser:ListRemove()
    local ListPush = self.CurrentToken
    self:CheckSetNextToken(self.Tokens.LPAREN)
    self:CheckSetNextToken(self.Tokens.VAR)
    local List = self.CurrentToken
    self:CheckSetNextToken(self.Tokens.COMMA)
    local ListIndex = self:Value()
    self:CheckSetNextToken(self.Tokens.RPAREN)
    return CAST.CBinaryNode:new(ListPush, CAST.CNode:new(List), ListIndex)
end

function CParser:ListLength()
    self:SetNextToken()
    return CAST.CUnaryNode:new(self.LastToken, CAST.CNode:new(self.CurrentToken))
end

function CParser:Expr()
    local Node = self:Term()
    while true do
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.ADD or self.CurrentToken.Type == self.Tokens.MIN) then
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
            Node = CAST.CBinaryNode:new(self.CurrentToken, Node, self:Value())
        else
            self:SetNextToken(self.LastToken)
            break
        end
    end
    return Node
end

function CParser:Value()
    self:SetNextToken()
    if (self.CurrentToken.Type == self.Tokens.NUM or self.CurrentToken.Type == self.Tokens.STR or self.CurrentToken.Type == self.Tokens.BOOL) then
        return CAST.CNode:new(self.CurrentToken)
    elseif (self.CurrentToken.Type == self.Tokens.VAR) then
        self:SetNextToken()
        if (self.CurrentToken.Type == self.Tokens.LPAREN) then
            self:SetNextToken(self.LastToken)
            return self:FunctionCall()
        elseif (self.CurrentToken.Type == self.Tokens.LBRACKET) then
            self:SetNextToken(self.LastToken)
            return self:ListMember()
        else
            self:SetNextToken(self.LastToken)
            return CAST.CNode:new(self.CurrentToken)
        end
    elseif (self.CurrentToken.Type == self.Tokens.ADD or self.CurrentToken.Type == self.Tokens.MIN) then
        return CAST.CUnaryNode:new(self.CurrentToken, self:Value())
    elseif (self.CurrentToken.Type == self.Tokens.LPAREN) then
        return self:Expr()
    elseif (self.CurrentToken.Type == self.Tokens.LBRACKET) then
        self:SetNextToken(self.LastToken)
        return CAST.CUnaryNode:new({ Type = self.Tokens.LIST, Value = "LIST" }, self:Parameters(false))
    elseif (self.CurrentToken.Type == self.Tokens.HASH) then
        return self:ListLength()
    else
        Error:Error("PARSER ERROR: UNEXPECTED IDENTIFIER " .. self.CurrentToken.Value .. " ON LINE " .. self.CurrentToken.LineNumber)
    end
end

function CParser:Parameters(IsRightParen)
    local Parameters = {}
    self:SetNextToken()
    while true do
        self:SetNextToken()
        if ((self.CurrentToken.Type == self.Tokens.RPAREN and IsRightParen == true) or (self.CurrentToken.Type == self.Tokens.RBRACKET and IsRightParen == false)) then
            break
        elseif (self.CurrentToken.Type == self.Tokens.COMMA) then
            ;
        elseif (self.CurrentToken.Type == self.Tokens.NUM_TYPE or self.CurrentToken.Type == self.Tokens.STR_TYPE or self.CurrentToken.Type == self.Tokens.BOOL_TYPE) then
            local VarType = self.CurrentToken
            self:SetNextToken()
            table.insert(Parameters, CAST.CUnaryNode:new(VarType, CAST.CNode:new(self.CurrentToken)))
        else
            self:SetNextToken(self.LastToken)
            table.insert(Parameters, self:Expr())
        end
    end
    return Parameters
end

function CParser:SemicolonTest()
    self:SetNextToken()
    if (self.CurrentToken.Type ~= self.Tokens.SEMI) then
        Error:Error("PARSER ERROR: EXCEPTED SEMICOLON ON LINE " .. self.CurrentToken.LineNumber)
    end
end

function CParser:CheckSetNextToken(Type)
    self:SetNextToken()
    if (self.CurrentToken.Type ~= Type) then
        Error:Error("UNEXPECTED IDENTIFIER " .. self.CurrentToken.Value .. " ON LINE " .. self.CurrentToken.LineNumber)
    end
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

return { CParser }