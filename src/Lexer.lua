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

return { CLexer }