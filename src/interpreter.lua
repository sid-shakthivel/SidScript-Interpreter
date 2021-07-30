local CLexer = require("src.lexer")[1]
local CParser = require("src.parser")[1]

CInterpreter = { Lexer, Parser }
CInterpreter.VariableTable = {}

function CInterpreter:new(LexerInput)
    NewInterpreter = {}
    setmetatable(NewInterpreter, self)
    NewInterpreter.Lexer = CLexer:new(LexerInput)
    NewInterpreter.Parser = CParser:new(NewInterpreter.Lexer)
    self.__index = self
    return NewInterpreter
end

function CInterpreter:Interpret(CurrentNode)
    if (CurrentNode == nil or CurrentNode.Token == nil) then
        return 0
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.ASSIGN) then
        local Expr = self:Interpret(CurrentNode.RightNode)
        if (CurrentNode.LeftNode.Token.Type == self.Lexer.Tokens.VAR) then
            if (tonumber(Expr) and  self.VariableTable[CurrentNode.LeftNode.Token.Value].Type == self.Lexer.Tokens.NUM) then
                self.VariableTable[CurrentNode.LeftNode.Token.Value].Expr = Expr
            end
        elseif (CurrentNode.LeftNode.Token.Type == self.Lexer.Tokens.NUM and tonumber(Expr)) then
            self.VariableTable[self:Interpret(CurrentNode.LeftNode)] = { Expr = Expr, Type = self.Lexer.Tokens.NUM }
        else
            error("Parsing Error")
        end
        return 0
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.ADD) then
        if (CurrentNode.NextNode) then
            return self:Interpret(CurrentNode.NextNode)
        else
            return self:Interpret(CurrentNode.LeftNode) + self:Interpret(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.MIN) then
        if (CurrentNode.NextNode) then
            return -self:Interpret(CurrentNode.NextNode)
        else
            return self:Interpret(CurrentNode.LeftNode) - self:Interpret(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.MUL) then
        return self:Interpret(CurrentNode.LeftNode) * self:Interpret(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.DIV) then
        return self:Interpret(CurrentNode.LeftNode) / self:Interpret(CurrentNode.RightNode)
    elseif (tonumber(CurrentNode.Token.Value)) then
        return tonumber(CurrentNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.VAR) then
        return self.VariableTable[CurrentNode.Token.Value].Expr
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.NUM) then
        return CurrentNode.NextNode.Token.Value
    end
end

function CInterpreter:Execute()
    Root = self.Parser:Program()

    for i = 1, #Root do
        self:Interpret(Root[i])
    end
end

return { CInterpreter }
