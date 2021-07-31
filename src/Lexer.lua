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
    BOOl = "BOOL"
}

function CLexer:new(input)
    NewLexer = {}
    setmetatable(NewLexer, self)
    NewLexer.Input = input
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
            return CToken:new("NUM_TYPE", self.Tokens.NUM_TYPE)
        end,
        ["str"] = function()
            return CToken:new("STR_TYPE", self.Tokens.STR_TYPE)
        end,
        ["bool"] = function()
            return CToken:new("BOOL_TYPE", self.Tokens.BOOL_TYPE)
        end,
        ["true"] = function ()
            return CToken:new("true", self.Tokens.BOOL)
        end,
        ["false"] = function ()
            return CToken:new("false", self.Tokens.BOOL)
        end
    }

    if (tonumber(Character)) then
        Token = CToken:new(self:GetNumber(), self.Tokens.NUM)
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
                if (Result:sub(1, 1) == "`") then
                    Token = CToken:new(string.gsub(self.Input:sub(OldPosition, NextSpace), "`", ""), self.Tokens.STR)
                else
                    Token = CToken:new(Result, self.Tokens.VAR)
                end
            end
            self.CurrentPosition = NextSpace
        end
    end

    self.CurrentPosition = self.CurrentPosition + 1
    return Token
end

return { CLexer }