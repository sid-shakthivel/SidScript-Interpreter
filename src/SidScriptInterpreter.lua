Error = {}

function Error:Error(str)
    print(str)
    os.exit()
end

CToken = { Value, Type, LineNumber }

function CToken:new(Value, Type, LineNumber)
    NewToken = {}
    setmetatable({}, self)
    NewToken.Value = Value
    NewToken.Type = Type
    NewToken.LineNumber = LineNumber
    self.__index = self
    return NewToken
end

CLexer = { CurrentPosition, LastPosition, Input, InvertedTokens, LineNumber }

CLexer.Tokens = {
    ADD = "+",
    MIN = "-",
    DIV = "/",
    MUL = "*",
    EOF = " ",
    LPAREN = "(",
    RPAREN = ")",
    LBRACKET = "[",
    RBRACKET = "]",
    ASSIGN = "=",
    SEMI = ";",
    COMMA = ",",
    DOT = ".",
    HASH = "#",
    GREATER = "<",
    LESSER = ">",
    EQUALS = "==",
    RBRACE = "}",
    LBRACE = "{",
    NUM_TYPE = "num",
    STR_TYPE = "str",
    BOOL_TYPE = "bool",
    VOID_TYPE = "void",
    LIST_TYPE = "list",
    PRINT = "print",
    RETURN = "return",
    IF = "if",
    ELSE = "else",
    WHILE = "while",
    FOR = "for",
    FUNC = "func",
    PUSH = "push",
    REMOVE = "remove",
    TRUE = "bool",
    FALSE = "bool",
    CALL = "CALL",
    NUM = "NUM",
    STR = "STR",
    BOOL = "BOOL",
    VOID = "VOID",
    LIST = "LIST",
    VAR = "VAR",
}

function CLexer:new(Input)
    NewLexer = {}
    setmetatable(NewLexer, self)
    NewLexer.Input = Input
    NewLexer.CurrentPosition = 1
    NewLexer.InvertedTokens = {}
    NewLexer.LineNumber = 0
    self.__index = self
    return NewLexer
end

function CLexer:GetNextToken()
    self.LastPosition = self.CurrentPosition

    if (self.CurrentPosition > #self.Input) then
        return CToken:new("EOF", self.Tokens.EOF, self.LineNumber)
    end

    local Character = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
    local Token

    while (Character == ' ' or Character == '\n') do
        if (Character == '\n') then
            self.LineNumber = self.LineNumber + 1
        end
        self.CurrentPosition = self.CurrentPosition + 1
        Character = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
    end

    if (tonumber(Character)) then
        Token = CToken:new(self:GetNumber(), self.Tokens.NUM, self.LineNumber)
    elseif (Character == "=" and self:Peek() == "=") then
        Token = CToken:new("==", self.Tokens.EQUALS, self.LineNumber)
        self.CurrentPosition = self.CurrentPosition + 1
    elseif (self.InvertedTokens[Character] ~= nil) then
        Token = CToken:new(Character, self.Tokens[self.InvertedTokens[Character]], self.LineNumber)
    elseif (Character == '`') then
        local NextTemplateLiteral = self.Input:find("`", (self.CurrentPosition+1)) - 1;
        local Result = self.Input:sub(self.CurrentPosition+1, NextTemplateLiteral)
        Token = CToken:new(Result, self.Tokens.STR, self.LineNumber)
        self.CurrentPosition = NextTemplateLiteral + 1
    else
        local NextLeftParenthesis = self.Input:find("%(", self.CurrentPosition) or #self.Input
        local NextRightParenthesis = self.Input:find("%)", self.CurrentPosition) or #self.Input
        local NextSpace = self.Input:find(" ", self.CurrentPosition) or #self.Input
        local NextSemi = self.Input:find(";", self.CurrentPosition) or #self.Input
        local NextComma = self.Input:find(",", self.CurrentPosition) or #self.Input
        local NextSign = self.Input:find("[*/+-]", self.CurrentPosition) or #self.Input
        local NextLeftBracket = self.Input:find("%[", self.CurrentPosition) or #self.Input
        local NextRightBracket = self.Input:find("%]", self.CurrentPosition) or #self.Input
        local Answer = math.min(NextLeftParenthesis, NextSpace, NextSemi, NextRightParenthesis, NextSign, NextLeftBracket, NextRightBracket, NextComma)
        local Result = self.Input:sub(self.CurrentPosition, (Answer-1))

        if (self.InvertedTokens[Result]) then
            Token = CToken:new(Result, self.Tokens[self.InvertedTokens[Result]], self.LineNumber)
        else
            Token = CToken:new(Result, self.Tokens.VAR, self.LineNumber)
        end
        self.CurrentPosition = Answer - 1
    end

    self.CurrentPosition = self.CurrentPosition + 1
    return Token
end

function CLexer:InvertTokens()
    for k,v in pairs(self.Tokens) do
        self.InvertedTokens[v] = k
    end
end

function CLexer:GetNumber()
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

function CLexer:Peek()
    return self.Input:sub((self.CurrentPosition+1), (self.CurrentPosition+1))
end

function CLexer:SetLastToken()
    self.CurrentPosition = self.LastPosition
end

CAST = {}

CAST.CProgramNode = { Children }

function CAST.CProgramNode:new()
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Children = {}
    self.__index = self
    return NewNode
end

CAST.CNode = { Token }

function CAST.CNode:new(Token)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = Token
    self.__index = self
    return NewNode
end

CAST.CUnaryNode = { Token, NextNode }

function CAST.CUnaryNode:new(Token, NextNode)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = Token
    NewNode.NextNode = NextNode
    self.__index = self
    return NewNode
end

CAST.CBinaryNode = { Token, LeftNode, RightNode }

function CAST.CBinaryNode:new(Token, LeftNode, RightNode)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = Token
    NewNode.LeftNode = LeftNode or nil
    NewNode.RightNode = RightNode or nil
    self.__index = self
    return NewNode
end

CAST.CTernaryNode = { Token, LeftNode, CentreNode, RightNode }

function CAST.CTernaryNode:new(Token, LeftNode, CentreNode, RightNode)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = Token
    NewNode.LeftNode = LeftNode or nil
    NewNode.CentreNode = CentreNode or nil
    NewNode.RightNode = RightNode or nil
    self.__index = self
    return NewNode
end

CAST.CQuaternaryNode = { Token, LeftNode, CentreLeftNode, CentreRightNode, RightNode }

function CAST.CQuaternaryNode:new(Token, LeftNode, CentreLeftNode, CentreRightNode, RightNode)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = Token
    NewNode.LeftNode = LeftNode or nil
    NewNode.CentreLeftNode = CentreLeftNode or nil
    NewNode.CentreRightNode = CentreRightNode or nil
    NewNode.RightNode = RightNode or nil
    self.__index = self
    return NewNode
end

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

CSymbol = { Name, Type }

function CSymbol:new(Name, Type)
    NewSymbol = {}
    setmetatable(NewSymbol, self)
    NewSymbol.Name = Name
    NewSymbol.Type = Type
    self.__index = self
    return NewSymbol
end

CFunctionSymbol = { Name, Type, Parameters }

function CFunctionSymbol:new(Name, Type, Parameters)
    NewFunctionSymbol = {}
    setmetatable(NewFunctionSymbol, self)
    NewFunctionSymbol.Name = Name
    NewFunctionSymbol.Type = Type
    NewFunctionSymbol.Parameters = Parameters
    self.__index = self
    return NewFunctionSymbol
end

CListSymbol = { Name, Type, Members }

function CListSymbol:new(Name, Type, Members)
    NewListSymbol = {}
    setmetatable(NewListSymbol, self)
    NewListSymbol.Name = Name
    NewListSymbol.Type = Type
    NewListSymbol.Members = Members
    self.__index = self
    return NewListSymbol
end

CSymbolTable = { Name, Symbols, EnclosingScope }

function CSymbolTable:new(Name, EnclosingScope)
    NewSymbolTable = {}
    setmetatable(NewSymbolTable, self)
    NewSymbolTable.Name = Name
    NewSymbolTable.Symbols = {}
    NewSymbolTable.EnclosingScope = EnclosingScope
    self.__index = self
    return NewSymbolTable
end

function CSymbolTable:SetSymbol(Symbol)
    self.Symbols[Symbol.Name] = Symbol
end

function CSymbolTable:GetSymbol(Name)
    if (self.Symbols[Name]) then
        return self.Symbols[Name]
    elseif (self.EnclosingScope == nil) then
        return nil
    else
        return self.EnclosingScope:GetSymbol(Name)
    end
end

function CSymbolTable:GetLastFunction(Scope)
    if (Scope.Name == "Global") then
        Error:Error("SEMANTIC ERROR: CAN ONLY RETURN IN FUNCTION")
    elseif (Scope.EnclosingScope:GetSymbol(Scope.Name) and Scope.EnclosingScope:GetSymbol(Scope.Name).Type == "NUM") then
        return Scope.EnclosingScope:GetSymbol(Scope.Name)
    else
        return CSymbolTable:GetLastFunction(Scope.EnclosingScope)
    end
end

function ConcatenateTable(Table1, Table2)
    local NewTable = {}
    for i = 1, #Table1 do
        NewTable[i] = Table1[i]
    end
    for i = 1, #Table2 do
        NewTable[#Table1+i] = Table2[i]
    end
    return NewTable
end

CSemanticAnalyser = { Tokens, CurrentScope, GlobalScope }

function CSemanticAnalyser:new(Tokens)
    NewSemanticAnalyser = {}
    setmetatable(NewSemanticAnalyser, self)
    NewSemanticAnalyser.Tokens = Tokens
    NewSemanticAnalyser.GlobalScope = CSymbolTable:new("Global", nil)
    NewSemanticAnalyser.CurrentScope = NewSemanticAnalyser.GlobalScope
    self.__index = self
    return NewSemanticAnalyser
end

function CSemanticAnalyser:Analyse(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.FUNC) then
        if (self.CurrentScope:GetSymbol(CurrentNode.CentreLeftNode.Token.Value) ~= nil) then
            Error:Error("SEMANTIC ERROR: FUNCTION OF NAME " .. CurrentNode.CentreLeftNode.Token.Value .. " ALREADY DECLARED")
        end
        for i = 1, #CurrentNode.LeftNode do
            self:GetFormattedVariableType(CurrentNode.LeftNode[i].Token)
        end
        local NewSymbol = CFunctionSymbol:new(CurrentNode.CentreLeftNode.Token.Value, self:GetFormattedVariableType(CurrentNode.CentreRightNode.Token), CurrentNode.LeftNode)
        self.CurrentScope:SetSymbol(NewSymbol)
        self:BuildSymbolTable(CurrentNode.CentreLeftNode.Token.Value, ConcatenateTable(CurrentNode.LeftNode, CurrentNode.RightNode))
    elseif (CurrentNode.Token.Type == self.Tokens.CALL) then
        local Function = self.CurrentScope:GetSymbol(CurrentNode.LeftNode.Token.Value)
        if (Function == nil) then
            Error:Error("SEMANTIC ERROR: NO FUNCTION OF NAME " .. CurrentNode.LeftNode.Token.Value)
        end
        if (#Function.Parameters ~= #CurrentNode.RightNode) then
            Error:Error("SEMANTIC ERROR: INSUFFICIENT ARGUMENTS PASSED TO FUNCTION " .. Function.Name)
        end
        for i = 1, #Function.Parameters do
            if (self:GetType(CurrentNode.RightNode[i]) == nil or self:GetFormattedVariableType(Function.Parameters[i].Token) ~= self:GetType(CurrentNode.RightNode[i]).Type) then
                Error:Error("SEMANTIC ERROR: ARGUMENTS TYPES MUST MATCH FUNCTION PARAMETERS TYPES ON LINE " .. CurrentNode.LeftNode.Token.LineNumber)
            end
        end
    elseif (CurrentNode.Token.Type == self.Tokens.RETURN) then
        if (self.CurrentScope.Name == "Global") then
            Error:Error("SEMANTIC ERROR: RETURN MUST BE CALLED IN FUNCTION ON LINE " .. CurrentNode.Token.LineNumber)
        end
        local Function = self.CurrentScope:GetLastFunction(self.CurrentScope)
        if (Function.Type == self.Tokens.VOID) then
            Error:Error("SEMANTIC ERROR: VOID FUNCTIONS CANNOT RETURN VALUES ON LINE ".. CurrentNode.Token.LineNumber)
        end
        local ReturnType = self:GetType(CurrentNode.NextNode)
        if (Function.Type ~= ReturnType.Type) then
            Error:Error("SEMANTIC ERROR: " .. Function.Type .. " FUNCTIONS CANNOT RETURN " .. ReturnType.Type .. " ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        local LeftSide = self:Analyse(CurrentNode.LeftNode)
        local RightSide = self:GetType(CurrentNode.RightNode)

        if (LeftSide.Type == self.Tokens.LIST_TYPE) then
            local NewListSymbol = CListSymbol:new(CurrentNode.LeftNode.NextNode.Token.Value, self.Tokens.LIST, CurrentNode.RightNode.NextNode)
            self.CurrentScope:SetSymbol(NewListSymbol)
            LeftSide = self.CurrentScope:GetSymbol(CurrentNode.LeftNode.NextNode.Token.Value)
        end

        if ((RightSide ~= nil and LeftSide.Type ~= RightSide.Type) and LeftSide.Type ~= self.Tokens.LIST) then
            Error:Error("SEMANTIC ERROR: VARIABLE OF TYPE " .. LeftSide.Type .. " CAN'T BE ASSIGNED TO " .. RightSide.Type .. " ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        if (self.CurrentScope:GetSymbol(CurrentNode.Token.Value) == nil) then
            Error:Error("SEMANTIC ERROR: VARIABLE " .. CurrentNode.Token.Value .. " NOT DECLARED ON LINE " .. CurrentNode.Token.LineNumber)
        else
            return self.CurrentScope:GetSymbol(CurrentNode.Token.Value)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE or CurrentNode.Token.Type == self.Tokens.STR_TYPE or CurrentNode.Token.Type == self.Tokens.BOOL_TYPE) then
        if (self.CurrentScope:GetSymbol(CurrentNode.NextNode.Token.Value) ~= nil) then
            Error:Error("SEMANTIC ERROR: VARIABLE " .. CurrentNode.NextNode.Token.Value .. " ALREADY DECLARED")
        end
        local NewSymbol = CSymbol:new(CurrentNode.NextNode.Token.Value, self:GetFormattedVariableType(CurrentNode.Token))
        self.CurrentScope:SetSymbol(NewSymbol)
        return self.CurrentScope:GetSymbol(CurrentNode.NextNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.LIST_TYPE) then
        if (self.CurrentScope:GetSymbol(CurrentNode.NextNode.Token.Value) ~= nil) then
            Error:Error("SEMANTIC ERROR: VARIABLE " .. CurrentNode.NextNode.Token.Value .. " ALREADY DECLARED")
        end
        return CurrentNode.Token
    elseif (CurrentNode.Token.Type == self.Tokens.LIST) then
        local List = self.CurrentScope:GetSymbol(CurrentNode.Token.Value)
        if (List == nil) then
            Error:Error("SEMANTIC ERROR: LIST OF NAME " .. CurrentNode.Token.Value .. " NOT DECLARED")
        end
        if (List.Type ~= self.Tokens.LIST) then
            Error:Error("SEMANTIC ERROR: CANNOT INDEX NON-LIST ON LINE " .. CurrentNode.Token.LineNumber)
        end
        return CurrentNode.Token
    elseif (CurrentNode.Token.Type == self.Tokens.IF) then
        self:Analyse(CurrentNode.CentreNode)
        --self.CurrentScope = NewSymbolTable.EnclosingScope
        self:BuildSymbolTable(("if " .. math.random(1000000)), CurrentNode.LeftNode)
        if (CurrentNode.RightNode ~= nil) then
            self:BuildSymbolTable(("else " .. math.random(1000000)), CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.WHILE) then
        self:Analyse(CurrentNode.LeftNode)
        self:BuildSymbolTable(("while " .. math.random(1000000)), CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.FOR) then
        self:Analyse(CurrentNode.LeftNode)
        self:Analyse(CurrentNode.CentreLeftNode)
        self:BuildSymbolTable(("for " .. math.random(1000000)), CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.LESSER or CurrentNode.Token.Type == self.Tokens.GREATER or CurrentNode.Token.Type == self.Tokens.EQUALS) then
        if (self:GetType(CurrentNode.LeftNode).Type ~= self:GetType(CurrentNode.RightNode).Type) then
            Error:Error("SEMANTIC ERROR: COMPARISON OF DIFFERENT TYPES ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.PUSH) then
        local List = self.CurrentScope:GetSymbol(CurrentNode.LeftNode.Token.Value)
        local NewListMember = self:GetType(CurrentNode.RightNode)
        if (List == nil) then
            Error:Error("SEMANTIC ERROR: LIST OF NAME " .. CurrentNode.LeftNode.Token.Value .. " NOT DECLARED")
        elseif (List.Type ~= self.Tokens.LIST) then
            Error:Error("SEMANTIC ERROR: CANNOT USE LIST OPERATION ON NON-LIST " .. CurrentNode.Token.LineNumber)
        elseif (NewListMember.Type ~= self.Tokens.NUM) then
            Error:Error("SEMANTIC ERROR: LISTS CAN ONLY CONTAIN NUMS ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.REMOVE) then
        local List = self.CurrentScope:GetSymbol(CurrentNode.LeftNode.Token.Value)
        local Index = self:GetType(CurrentNode.RightNode)
        if (List == nil) then
            Error:Error("SEMANTIC ERROR: LIST OF NAME " .. CurrentNode.LeftNode.Token.Value .. " NOT DECLARED")
        elseif (List.Type ~= self.Tokens.LIST) then
            Error:Error("SEMANTIC ERROR: CANNOT USE LIST OPERATION ON NON-LIST " .. CurrentNode.Token.LineNumber)
        elseif (Index.Type ~= self.Tokens.NUM) then
            Error:Error("SEMANTIC ERROR: CANNOT INDEX A LIST WITH A NON NUM" .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.PRINT) then
        self:GetType(CurrentNode.NextNode)
    end
end

function CSemanticAnalyser:BuildSymbolTable(Name, Body)
    local NewScope = CSymbolTable:new(Name, self.CurrentScope)
    self.CurrentScope = NewScope
    for i = 1, #Body do
        self:Analyse(Body[i])
    end
    self.CurrentScope = NewScope.EnclosingScope
end

function CSemanticAnalyser:GetFormattedVariableType(Token)
    if (Token.Type == self.Tokens.NUM_TYPE) then
        return self.Tokens.NUM
    elseif (Token.Type == self.Tokens.STR_TYPE) then
        return self.Tokens.STR
    elseif (Token.Type == self.Tokens.BOOL_TYPE) then
        return self.Tokens.BOOL
    elseif (Token.Type == self.Tokens.VOID_TYPE) then
        return self.Tokens.VOID
    elseif (Token.Type == self.Tokens.LIST_TYPE) then
        return self.Tokens.LIST
    else
        Error:Error("SEMANTIC ERROR: UNEXPECTED IDENTIFIER " .. Token.Value)
    end
end

function CSemanticAnalyser:GetType(CurrentNode)
    if (CurrentNode == nil) then
        return nil
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE or CurrentNode.Token.Type == self.Tokens.STR_TYPE or CurrentNode.Token.Type == self.Tokens.BOOL_TYPE) then
        return self:GetType(CurrentNode.NextNode)
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        return self.CurrentScope:GetSymbol(CurrentNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM or CurrentNode.Token.Type == self.Tokens.STR or CurrentNode.Token.Type == self.Tokens.BOOL) then
        return CurrentNode.Token
    elseif (CurrentNode.Token.Type == self.Tokens.MUL) then
        if (self:GetType(CurrentNode.RightNode).Type == self.Tokens.NUM and self:GetType(CurrentNode.LeftNode)) then
            return self:GetType(CurrentNode.RightNode)
        else
            Error:Error("SEMANTIC ERROR: MULTIPLICATION OF NON NUMBERS ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.MIN) then
        if (self:GetType(CurrentNode.RightNode).Type == self.Tokens.NUM and self:GetType(CurrentNode.LeftNode)) then
            return self:GetType(CurrentNode.RightNode)
        else
            Error:Error("SEMANTIC ERROR: SUBTRACTION OF NON NUMBERS ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.DIV) then
        if (self:GetType(CurrentNode.RightNode).Type == self.Tokens.NUM and self:GetType(CurrentNode.LeftNode)) then
            return self:GetType(CurrentNode.RightNode)
        else
            Error:Error("SEMANTIC ERROR: DIVISION OF NON NUMBERS ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.ADD) then
        if (CurrentNode.NextNode) then
            if (self:GetType(CurrentNode.NextNode).Type == self.Tokens.NUM) then
                return self:GetType(CurrentNode.NextNode)
            else
                Error:Error("SEMANTIC ERROR: ADDITION OF NON NUMBERS ON LINE " .. CurrentNode.Token.LineNumber)
            end
        else
            if (self:GetType(CurrentNode.RightNode).Type == self.Tokens.NUM and self:GetType(CurrentNode.LeftNode)) then
                return self:GetType(CurrentNode.RightNode)
            else
                Error:Error("SEMANTIC ERROR: ADDITION OF NON NUMBERS ON LINE " .. CurrentNode.Token.LineNumber)
            end
        end
    elseif (CurrentNode.Token.Type == self.Tokens.CALL) then
        return self.CurrentScope:GetSymbol(CurrentNode.LeftNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.HASH) then
        local List = self.CurrentScope:GetSymbol(CurrentNode.NextNode.Token.Value)
        if (List == nil) then
            Error:Error("SEMANTIC ERROR: LIST OF NAME " .. CurrentNode.NextNode.Token.Value .. " NOT DECLARED")
        elseif (List.Type ~= self.Tokens.LIST) then
            Error:Error("SEMANTIC ERROR: CANNOT USE LIST OPERATION ON NON-LIST" .. CurrentNode.Token.LineNumber)
        else
            return { Type = self.Tokens.NUM }
        end
    elseif (CurrentNode.Token.Type == self.Tokens.LIST) then
        if (CurrentNode.NextNode.Token) then
            local Index = self:GetType(CurrentNode.NextNode)
            local List = self.CurrentScope:GetSymbol(CurrentNode.Token.Value)
            if (List == nil) then
                Error:Error("SEMANTIC ERROR: LIST OF NAME " .. CurrentNode.Token.Value .. " NOT DECLARED")
            elseif (List.Type ~= self.Tokens.LIST) then
                Error:Error("SEMANTIC ERROR: CANNOT INDEX NON-LIST ON LINE " .. CurrentNode.Token.LineNumber)
            elseif (Index.Type ~= self.Tokens.NUM) then
                Error:Error("SEMANTIC ERROR: CANNOT INDEX A LIST WITH A NON NUM ON LINE " .. CurrentNode.Token.LineNumber)
            else
                if (List.Members[1] == nil) then
                    Error:Error("SEMANTIC ERROR: CANNOT INDEX A EMPTY LIST ON LINE " .. CurrentNode.Token.LineNumber)
                else
                    return List.Members[1].Token
                end
            end
        else
            for i = 1, #CurrentNode.NextNode do
                if (self:GetType(CurrentNode.NextNode[i]).Type ~= self.Tokens.NUM) then
                    Error:Error("SEMANTIC ERROR: LISTS CAN ONLY CONTAIN NUMS ON LINE" .. CurrentNode.Token.LineNumber)
                end
            end
            return CurrentNode.Token
        end
    end
end

CStackFrame = { Name, EncapsulatingScope, Members }

function CStackFrame:new(Name, EncapsulatingScope)
    NewStackFrame = {}
    setmetatable(NewStackFrame, self)
    NewStackFrame.Name = Name
    NewStackFrame.EncapsulatingScope = EncapsulatingScope
    NewStackFrame.Members = {}
    self.__index = self
    return NewStackFrame
end

function CStackFrame:SetItem(Key, Value)
    self.Members[Key] = Value
end

function CStackFrame:SetListItem(Key, Index, Value)
    self.Members[Key][Index].Token.Value = Value
end

function CStackFrame:GetItem(Key)
    if (self.Members[Key] ~= nil) then
        return self.Members[Key]
    elseif (self.Members[Key] == nil and self.EncapsulatingScope ~= nil) then
        return self.EncapsulatingScope:GetItem(Key)
    else
        return nil
    end
end

CStack = { StackFrames }

function CStack:new()
    NewStack = {}
    setmetatable(NewStack, self)
    NewStack.StackFrames = {}
    self.__index = self
    return NewStack
end

function CStack:Push(NewStackFrame)
    return table.insert(self.StackFrames, NewStackFrame)
end

function CStack:Pop()
    return table.remove(self.StackFrames)
end

function CStack:Peek()
    return self.StackFrames[#self.StackFrames]
end

CInterpreter = { Lexer, Parser, SemanticAnalyser, Tokens, CallStack }

function CInterpreter:new(LexerInput)
    NewInterpreter = {}
    setmetatable(NewInterpreter, self)
    NewInterpreter.Lexer = CLexer:new(LexerInput)
    NewInterpreter.Lexer:InvertTokens()
    NewInterpreter.Parser = CParser:new(NewInterpreter.Lexer)
    NewInterpreter.SemanticAnalyser = CSemanticAnalyser:new(NewInterpreter.Lexer.Tokens)
    NewInterpreter.Tokens = NewInterpreter.Lexer.Tokens
    NewInterpreter.CallStack = CStack:new()
    self.__index = self
    return NewInterpreter
end

function CInterpreter:ExpressionAssignmentEvaluator(CurrentNode)
    if (CurrentNode == nil) then
        return nil
    elseif (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        local Variable = CurrentNode.LeftNode.Token.Value
        if (CurrentNode.LeftNode.Token.Type == self.Tokens.LIST) then
            return self:ListEvaluator(CurrentNode)
        end
        if (CurrentNode.LeftNode.NextNode) then
            Variable = self:ExpressionAssignmentEvaluator(CurrentNode.LeftNode)
        end
        local Value = self:ExpressionAssignmentEvaluator(CurrentNode.RightNode)
        self.CallStack:Peek():SetItem(Variable, Value)
        return self.CallStack:Peek():GetItem(Variable)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE or CurrentNode.Token.Type == self.Tokens.STR_TYPE or CurrentNode.Token.Type == self.Tokens.BOOL_TYPE or CurrentNode.Token.Type == self.Tokens.LIST_TYPE) then
        return self:ExpressionAssignmentEvaluator(CurrentNode.NextNode)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM or CurrentNode.Token.Type == self.Tokens.STR or CurrentNode.Token.Type == self.Tokens.BOOL) then
        return CurrentNode.Token.Value
    elseif (CurrentNode.Token.Type == self.Tokens.LIST) then
        if (CurrentNode.NextNode.Token) then
            local Index = self:ExpressionAssignmentEvaluator(CurrentNode.NextNode)
            return self:ExpressionAssignmentEvaluator(self.CallStack:Peek():GetItem(CurrentNode.Token.Value)[Index])
        else
            return CurrentNode.NextNode
        end
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        if (self.CallStack:Peek():GetItem(CurrentNode.Token.Value) == nil) then
            return CurrentNode.Token.Value
        else
            return self.CallStack:Peek():GetItem(CurrentNode.Token.Value)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.MUL) then
        return self:ExpressionAssignmentEvaluator(CurrentNode.LeftNode) * self:ExpressionAssignmentEvaluator(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.MIN) then
        return self:ExpressionAssignmentEvaluator(CurrentNode.LeftNode) - self:ExpressionAssignmentEvaluator(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.DIV) then
        return self:ExpressionAssignmentEvaluator(CurrentNode.LeftNode) / self:ExpressionAssignmentEvaluator(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.ADD) then
        if (CurrentNode.NextNode) then
            return self:ExpressionAssignmentEvaluator(CurrentNode.NextNode) + 1
        else
            return self:ExpressionAssignmentEvaluator(CurrentNode.LeftNode) + self:ExpressionAssignmentEvaluator(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.CALL) then
        return self:FunctionEvaluator(CurrentNode)
    elseif (CurrentNode.Token.Type == self.Tokens.HASH) then
        return self:ListEvaluator(CurrentNode)
    end
end

function CInterpreter:ConditionalEvaluator(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.IF) then
        local Condition = self:ConditionalEvaluator(CurrentNode.CentreNode)
        if (Condition == true) then
            return self:Interpret(CurrentNode.LeftNode)
        elseif (Condition == false and CurrentNode.RightNode) then
            return self:Interpret(CurrentNode.RightNode)
        end
        return 0
    elseif (CurrentNode.Token.Type == self.Tokens.EQUALS) then
        return self:ExpressionAssignmentEvaluator(CurrentNode.LeftNode) == self:ExpressionAssignmentEvaluator(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.GREATER) then
        return self:ExpressionAssignmentEvaluator(CurrentNode.LeftNode) < self:ExpressionAssignmentEvaluator(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.LESSER) then
        return self:ExpressionAssignmentEvaluator(CurrentNode.LeftNode) > self:ExpressionAssignmentEvaluator(CurrentNode.RightNode)
    end
end

function CInterpreter:GetVariableName(CurrentNode)
    if (CurrentNode.Token.Value == self.Tokens.ASSIGN)then
        return self:GetVariableName(CurrentNode.LeftNode)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE or CurrentNode.Token.Type == self.Tokens.STR_TYPE or CurrentNode.Token.Type == self.Tokens.BOOL_TYPE) then
        return self:GetVariableName(CurrentNode.NextNode)
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        return CurrentNode.Token.Value
    end
end

function CInterpreter:IterativeEvaluator(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.WHILE) then
        while true do
            if (self:ConditionalEvaluator(CurrentNode.LeftNode) == true) then
                self:Interpret(CurrentNode.RightNode)
            else
                break
            end
        end
    elseif (CurrentNode.Token.Type == self.Tokens.FOR) then
        local VariableName = self:GetVariableName(CurrentNode.LeftNode)
        self:ExpressionAssignmentEvaluator(CurrentNode.LeftNode)
        while true do
            if (self:ConditionalEvaluator(CurrentNode.CentreLeftNode) == true) then
                self:Interpret(CurrentNode.RightNode)
            else
                break
            end
            self.CallStack:Peek():SetItem(VariableName, self:ExpressionAssignmentEvaluator(CurrentNode.CentreRightNode))
        end
    end
    return 0
end

function CInterpreter:FunctionEvaluator(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.FUNC) then
        self.CallStack:Peek():SetItem(CurrentNode.CentreLeftNode.Token.Value, CurrentNode)
    elseif (CurrentNode.Token.Type == self.Tokens.CALL) then
        local Function = self.CallStack:Peek():GetItem(CurrentNode.LeftNode.Token.Value)
        local NewStackFrame = CStackFrame:new(CurrentNode.LeftNode.Token.Value, self.CallStack:Peek())
        self.CallStack:Push(NewStackFrame)
        for i = 1, #Function.LeftNode do
            self.CallStack:Peek():SetItem(self:GetVariableName(Function.LeftNode[i]), self:ExpressionAssignmentEvaluator(CurrentNode.RightNode[i]))
        end
        local ReturnValue = self:Interpret(Function.RightNode)
        self.CallStack:Pop()
        return ReturnValue
    end
end

function CInterpreter:ListEvaluator(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        local ListName = CurrentNode.LeftNode.Token.Value
        local ListIndex = nil
        local Value = self:ExpressionAssignmentEvaluator(CurrentNode.RightNode)
        if (CurrentNode.LeftNode.NextNode) then
            ListIndex = CurrentNode.LeftNode.NextNode.Token.Value
            self.CallStack:Peek():SetListItem(ListName, ListIndex, Value)
            return self.CallStack:Peek():GetItem(ListName)[ListIndex]
        else
            self.CallStack:Peek():SetItem(ListName, Value)
            return self.CallStack:Peek():GetItem(ListName)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.PUSH) then
        local ListName = CurrentNode.LeftNode.Token.Value
        table.insert(self.CallStack:Peek():GetItem(ListName), CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.REMOVE) then
        local ListName = CurrentNode.LeftNode.Token.Value
        local List= self.CallStack:Peek():GetItem(ListName)
        local Index = self:ExpressionAssignmentEvaluator(CurrentNode.RightNode)
        if (Index > #List or Index < 1) then
            Error:Error("INTERPRETER ERROR: LIST " .. ListName .. " IS OUT OUT BOUNDS ON LINE " .. CurrentNode.Token.LineNumber)
        end
        table.remove(List, Index)
    elseif (CurrentNode.Token.Type == self.Tokens.HASH) then
        local ListName = CurrentNode.NextNode.Token.Value
        return (#(self.CallStack:Peek():GetItem(ListName))) + 1
    end
end

function CInterpreter:MainEvaluator(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        return self:ExpressionAssignmentEvaluator(CurrentNode)
    elseif (CurrentNode.Token.Type == self.Tokens.IF) then
        return self:ConditionalEvaluator(CurrentNode)
    elseif (CurrentNode.Token.Type == self.Tokens.WHILE or CurrentNode.Token.Type == self.Tokens.FOR) then
        return self:IterativeEvaluator(CurrentNode)
    elseif (CurrentNode.Token.Type == self.Tokens.PRINT) then
        print(self:ExpressionAssignmentEvaluator(CurrentNode.NextNode))
    elseif (CurrentNode.Token.Type == self.Tokens.FUNC or CurrentNode.Token.Type == self.Tokens.CALL) then
        return self:FunctionEvaluator(CurrentNode)
    elseif (CurrentNode.Token.Type == self.Tokens.RETURN) then
        return self:ExpressionAssignmentEvaluator(CurrentNode.NextNode)
    elseif (CurrentNode.Token.Type == self.Tokens.PUSH or CurrentNode.Token.Type == self.Tokens.REMOVE) then
        return self:ListEvaluator(CurrentNode)
    end
    return 0
end

function CInterpreter:Interpret(Root)
    local CurrentLine
    for i = 1, #Root do
        CurrentLine = self:MainEvaluator(Root[i])
    end
    return CurrentLine
end

function CInterpreter:Execute()
    local Root = self.Parser:Program()

    for i = 1, #Root do
        self.SemanticAnalyser:Analyse(Root[i])
    end

    self.CallStack:Push(CStackFrame:new("Main", nil))
    self:Interpret(Root)
    self.CallStack:Pop()
end

local FileName = arg[1]

if (FileName == nil) then
    Error:Error("FILE ERROR: FILE NOT GIVEN")
elseif (FileName:sub(#FileName-3, #FileName) ~= ".txt") then
    Error:Error("FILE ERROR: FILE MUST BE A .TXT")
elseif (assert(io.open(FileName, "r")) == false) then
    Error:Error("FILE ERROR: CANNOT OPEN FILE " .. FileName)
end

function trim (s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

local File = io.open(FileName, "r")
local Program = ""
local CurrentLine = File:read("*line")

while CurrentLine ~= nil do
    Program = Program .. "\n" .. CurrentLine
    CurrentLine = File:read("*line")
    if (CurrentLine ~= nil) then
        CurrentLine = trim(CurrentLine)
    end
end

File:close()

Interpreter = CInterpreter:new(Program)
Interpreter:Execute()
