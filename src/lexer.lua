CToken = { Value, Type }

function CToken:new(value, type)
    NewToken = {}
    setmetatable({}, self)
    NewToken.Value = value
    NewToken.Type = type
    self.__index = self
    return NewToken
end

CLexer = { CurrentPosition, Input }

CLexer.Tokens = {
    INTEGER = "INTEGER",
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
    NUM = "NUM",
    STR = "STR",
    BOOL = "BOOL"
}

function CLexer:new(input)
    NewLexer = {}
    setmetatable(NewLexer, self)
    NewLexer.Input = input
    NewLexer.CurrentPosition = 1
    self.__index = self
    return NewLexer
end

function CLexer:GetInteger()
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

function CLexer:GetNextToken()
    local Character = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
    local Token

    if (Character == ' ') then
        self.CurrentPosition = self.CurrentPosition + 1
        Character = self.Input:sub(self.CurrentPosition, self.CurrentPosition)
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
            return CToken:new("NUM", self.Tokens.NUM)
        end,
        ["str"] = function()
            return CToken:new("STR", self.Tokens.STR)
        end,
        ["bool"] = function()
            return CToken:new("BOOL", self.Tokens.BOOL)
        end
    }

    if (tonumber(Character)) then
        Token = CToken:new(self:GetInteger(), self.Tokens.INTEGER)
    else
        if (SingleCharacterCases[Character]) then
            Token = SingleCharacterCases[Character]()
        else
            local OldPosition = self.CurrentPosition
            local NextSpace = string.find(self.Input, " ", self.CurrentPosition) or #self.Input + 1
            local Result = string.gsub(self.Input:sub(OldPosition, NextSpace-1), ";", "")
            if (MultiCharacterCases[Result]) then
                Token = MultiCharacterCases[Result]()
            else
                Token = CToken:new(Result, self.Tokens.VAR)
            end
            self.CurrentPosition = NextSpace
        end
    end

    self.CurrentPosition = self.CurrentPosition + 1
    return Token
end

return { CLexer }