local CLexer = require("src.Lexer")[1]
local CParser = require("src.Parser")[1]
local CSymbolTable = require("src.SymbolTable")[1]

CInterpreter = { Lexer, Parser, SymbolTable, Tokens }
CInterpreter.VariableTable = {}

function CInterpreter:new(LexerInput)
    NewInterpreter = {}
    setmetatable(NewInterpreter, self)
    NewInterpreter.Lexer = CLexer:new(LexerInput)
    NewInterpreter.Parser = CParser:new(NewInterpreter.Lexer)
    NewInterpreter.SymbolTable = CSymbolTable:new(NewInterpreter.Lexer.Tokens, self.VariableTable)
    NewInterpreter.Tokens = NewInterpreter.Lexer.Tokens
    self.__index = self
    return NewInterpreter
end

function CInterpreter:SetVariable(Name, Value)
    self.VariableTable[Name] = Value
end

function CInterpreter:GetVariable(Name)
    return self.VariableTable[Name]
end

function CInterpreter:Interpret(CurrentNode)
    if (CurrentNode == nil or CurrentNode.Token == nil) then
        return 0
    elseif (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        local VariableType = CurrentNode.LeftNode.Token.Type
        local Variable = self:Interpret(CurrentNode.LeftNode)
        if (VariableType == VAR) then
            VariableType = self.SymbolTable:GetVariable(Variable.Value).Type
        end
        local Value = nil
        if (VariableType == self.Tokens.NUM_TYPE) then
            Value = self:ArithmeticEvaluator(CurrentNode.RightNode)
        elseif (VariableType == self.Tokens.STR_TYPE) then
            Value = self:Interpret(CurrentNode.RightNode).Value
        elseif (VariableType == self.Tokens.BOOL_TYPE) then
            Value = self:Interpret(CurrentNode.RightNode).Value
        end
        self:SetVariable(Variable.Name, Value)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE or CurrentNode.Token.Type == self.Tokens.STR_TYPE or CurrentNode.Token.Type == self.Tokens.BOOL_TYPE) then
        return self:Interpret(CurrentNode.NextNode)
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        return CurrentNode.Token
    elseif (CurrentNode.Token.Type == self.Tokens.STR) then
        return CurrentNode.Token
    elseif (CurrentNode.Token.Type == self.Tokens.BOOL) then
        return CurrentNode.Token
    end
end


function CInterpreter:ArithmeticEvaluator(CurrentNode)
    if (CurrentNode == nil or CurrentNode.Token == nil) then
        return 0
    elseif (CurrentNode.Token.Type == self.Tokens.ADD) then
        if (CurrentNode.NextNode) then
            return self:Interpret(CurrentNode.NextNode)
        else
            return self:Interpret(CurrentNode.LeftNode) + self:Interpret(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.MIN) then
        if (CurrentNode.NextNode) then
            return -self:Interpret(CurrentNode.NextNode)
        else
            return self:Interpret(CurrentNode.LeftNode) - self:Interpret(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.MUL) then
        return self:Interpret(CurrentNode.LeftNode) * self:Interpret(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.DIV) then
        return self:Interpret(CurrentNode.LeftNode) / self:Interpret(CurrentNode.RightNode)
    elseif (tonumber(CurrentNode.Token.Value)) then
        return tonumber(CurrentNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        return self:GetVariable(CurrentNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE) then
        return CurrentNode.NextNode.Token.Value
    end
end

function CInterpreter:Execute()
    Root = self.Parser:Program()

    --for i = 1, #Root do
    --    self.SymbolTable:BuildSymbolTable(Root[i])
    --end

    --for i = 1, #Root do
    --    self:Interpret(Root[i])
    --end
end

return { CInterpreter }
