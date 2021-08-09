CToken = { Value, Type }

function CToken:new(value, type)
    NewToken = {}
    setmetatable({}, self)
    NewToken.Value = value
    NewToken.Type = type
    self.__index = self
    return NewToken
end

CLexer = { CurrentPosition, Input, LastPosition }

CLexer.Tokens = {
    ADD = "ADD",
    MIN = "MIN",
    DIV = "DIV",
    MUL = "MUL",
    EOF = "EOF",
    LPAREN = "LPAREN",
    RPAREN = "RPAREN",
    START = "START",
    FINISH = "FINISH",
    DOT = "DOT",
    ASSIGN = "ASSIGN",
    VAR = "VAR",
    SEMI = "SEMI",
    NUM_TYPE = "NUM_TYPE",
    STR_TYPE = "STR_TYPE",
    BOOL_TYPE = "BOOL_TYPE",
    NUM = "NUM",
    STR = "STR",
    BOOL = "BOOL",
    IF = "IF",
    ELSE = "ELSE",
    GREATER = "GREATER",
    LESSER = "LESSER",
    EQUALS = "EQUALS",
    COLON = "COLON",
    RBRACE = "RBRACE",
    LBRACE = "LBRACE",
    PRINT = "PRINT",
    WHILE = "WHILE",
    FOR = "FOR",
    COMMA = "COMMA",
    FUNC = "FUNC",
    CALL = "CALL",
    VOID_TYPE = "VOID"
}

function CLexer:new(Input)
    NewLexer = {}
    setmetatable(NewLexer, self)
    NewLexer.Input = Input
    NewLexer.CurrentPosition = 1
    self.__index = self
    return NewLexer
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

function CLexer:GetNextToken()
    self.LastPosition = self.CurrentPosition
    local Character = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
    local Token

    while Character == ' ' do
        self.CurrentPosition = self.CurrentPosition + 1
        Character = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
    end

    if (self:Peek() == '=' and Character == '=') then
        self.CurrentPosition = self.CurrentPosition + 2
        return CToken:new('==', self.Tokens.EQUALS)
    end

    SingleCharacterCases = {
        ['+'] = function()
            return CToken:new('+', self.Tokens.ADD)
        end,
        ['-'] = function()
            return CToken:new('-', self.Tokens.MIN)
        end,
        ['*'] = function()
            return CToken:new('*', self.Tokens.MUL)
        end,
        ['/'] = function()
            return CToken:new('/', self.Tokens.DIV)
        end,
        ['('] = function()
            return CToken:new('(', self.Tokens.LPAREN)
        end,
        [')'] = function()
            return CToken:new(')', self.Tokens.RPAREN)
        end,
        ['.'] = function()
            return CToken:new('.', self.Tokens.DOT)
        end,
        [';'] = function()
            return CToken:new(';', self.Tokens.SEMI)
        end,
        ['='] = function()
            return CToken:new('=', self.Tokens.ASSIGN)
        end,
        ['>'] = function()
            return CToken:new('>', self.Tokens.GREATER)
        end,
        ['<'] = function()
            return CToken:new('<', self.Tokens.LESSER)
        end,
        [':'] = function()
            return CToken:new(':', self.Tokens.COLON)
        end,
        ['{'] = function()
            return CToken:new('{', self.Tokens.LBRACE)
        end,
        ['}'] = function()
            return CToken:new('}', self.Tokens.RBRACE)
        end
    }

    MultiCharacterCases = {
        ["START"] = function()
            return CToken:new("START", self.Tokens.START)
        end,
        ["FINISH"] = function()
            return CToken:new("FINISH", self.Tokens.FINISH)
        end,
        ["num"] = function()
            return CToken:new("NUM_TYPE", self.Tokens.NUM_TYPE)
        end,
        ["str"] = function()
            return CToken:new("STR_TYPE", self.Tokens.STR_TYPE)
        end,
        ["bool"] = function()
            return CToken:new("BOOL_TYPE", self.Tokens.BOOL_TYPE)
        end,
        ["true"] = function()
            return CToken:new("true", self.Tokens.BOOL)
        end,
        ["false"] = function()
            return CToken:new("false", self.Tokens.BOOL)
        end,
        ["if"] = function()
            return CToken:new("if", self.Tokens.IF)
        end,
        ["else"] = function()
            return CToken:new("else", self.Tokens.ELSE)
        end,
        ["print"] = function ()
            return CToken:new("print", self.Tokens.PRINT)
        end,
        ["while"] = function()
            return CToken:new("while", self.Tokens.WHILE)
        end,
        ["for"] = function()
            return CToken:new("for", self.Tokens.FOR)
        end,
        ["func"] = function()
            return CToken:new("func", self.Tokens.FUNC)
        end,
        ["void"] = function()
            return CToken:new("void", self.Tokens.VOID_TYPE)
        end
    }

    if (tonumber(Character)) then
        Token = CToken:new(self:GetNumber(), self.Tokens.NUM)
    else
        if (SingleCharacterCases[Character]) then
            Token = SingleCharacterCases[Character]()
        else
            local OldPosition = self.CurrentPosition

            local NextParenthesis = self.Input:find(")", self.CurrentPosition) or #self.Input
            local NextSpace = self.Input:find(" ", self.CurrentPosition) or #self.Input
            local NextSemi = self.Input:find(";", self.CurrentPosition) or #self.Input
            local FinalCharacter
            local Result

            if (NextSpace < NextSemi and NextSpace < NextParenthesis) then
                NextSpace = NextSpace - 1
                Result = self.Input:sub(OldPosition, NextSpace)
                FinalCharacter = NextSpace
            elseif (NextSemi < NextSpace and NextSemi < NextParenthesis) then
                NextSemi = NextSemi - 1
                Result = self.Input:sub(OldPosition, NextSemi)
                FinalCharacter = NextSemi
            elseif (NextParenthesis < NextSpace and NextParenthesis < NextSemi) then
                NextParenthesis = NextParenthesis - 1
                Result = self.Input:sub(OldPosition, NextParenthesis)
                FinalCharacter = NextParenthesis
            else
                Result = self.Input:sub(OldPosition, NextSpace)
                FinalCharacter = NextSpace
            end

            if (MultiCharacterCases[Result]) then
                Token = MultiCharacterCases[Result]()
            else
                if (Result:sub(1, 1) == "`") then
                    local NextStringLiteral = string.find(self.Input, "`", FinalCharacter)
                    Result = string.sub(self.Input, self.CurrentPosition, NextStringLiteral)
                    Token = CToken:new(string.gsub(Result, "`", ""), self.Tokens.STR)
                    FinalCharacter = NextStringLiteral
                else
                    Token = CToken:new(Result, self.Tokens.VAR)
                end
            end

            self.CurrentPosition = FinalCharacter
        end
    end

    self.CurrentPosition = self.CurrentPosition + 1
    return Token
end

function CLexer:SetLastToken()
    self.CurrentPosition = self.LastPosition
end

return { CLexer }