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

function CInterpreter:ArithmeticEvaluator(CurrentNode)
    if (CurrentNode == nil or CurrentNode.Token == nil) then
        return 0
    elseif (CurrentNode.Token.Type == self.Tokens.ADD) then
        if (CurrentNode.NextNode) then
            return self:ArithmeticEvaluator(CurrentNode.NextNode)
        else
            return self:ArithmeticEvaluator(CurrentNode.LeftNode) + self:ArithmeticEvaluator(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.MIN) then
        if (CurrentNode.NextNode) then
            return -self:ArithmeticEvaluator(CurrentNode.NextNode)
        else
            return self:ArithmeticEvaluator(CurrentNode.LeftNode) - self:ArithmeticEvaluator(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.MUL) then
        return self:ArithmeticEvaluator(CurrentNode.LeftNode) * self:ArithmeticEvaluator(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.DIV) then
        return self:ArithmeticEvaluator(CurrentNode.LeftNode) / self:ArithmeticEvaluator(CurrentNode.RightNode)
    elseif (tonumber(CurrentNode.Token.Value)) then
        return tonumber(CurrentNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        return self:GetVariable(CurrentNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE) then
        return CurrentNode.NextNode.Token.Value
    elseif (CurrentNode.Token.Type == self.Tokens.NUM) then
        return CurrentNode.Token.Value
    end
end

function CInterpreter:VariableEvaluator(CurrentNode)
    if (CurrentNode == nil or CurrentNode.Token == nil) then
        return 0
    elseif (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        local VariableType = CurrentNode.LeftNode.Token.Type
        local Variable = self:VariableEvaluator(CurrentNode.LeftNode)
        if (VariableType == self.Tokens.VAR) then
            VariableType = self.SymbolTable:GetSymbol(Variable.Value).Type
        end
        local Value
        if (VariableType == self.Tokens.NUM_TYPE) then
            Value = self:ArithmeticEvaluator(CurrentNode.RightNode)
        elseif (VariableType == self.Tokens.STR_TYPE) then
            Value = self:VariableEvaluator(CurrentNode.RightNode).Value
        elseif (VariableType == self.Tokens.BOOL_TYPE) then
            Value = self:VariableEvaluator(CurrentNode.RightNode).Value
        end
        self:SetVariable(Variable.Value, Value)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE or CurrentNode.Token.Type == self.Tokens.STR_TYPE or CurrentNode.Token.Type == self.Tokens.BOOL_TYPE) then
        return self:VariableEvaluator(CurrentNode.NextNode)
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        return CurrentNode.Token
    elseif (CurrentNode.Token.Type == self.Tokens.STR) then
        return CurrentNode.Token
    elseif (CurrentNode.Token.Type == self.Tokens.BOOL) then
        return CurrentNode.Token
    end
end

function CInterpreter:MainEvaluator(CurrentNode)
    if (CurrentNode == nil or CurrentNode.Token == nil) then
        return 0
    elseif (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        return self:VariableEvaluator(CurrentNode)
    elseif (CurrentNode.Token.Type == self.Tokens.IF) then
        local Condition = self:MainEvaluator(CurrentNode.CentreNode)
        if (Condition == false) then
            return self:Interpret(CurrentNode.RightNode)
        elseif (Condition == true) then
            return self:Interpret(CurrentNode.LeftNode)
        else
            return 0
        end
    elseif (CurrentNode.Token.Type == self.Tokens.GREATER) then
        return self:ArithmeticEvaluator(CurrentNode.LeftNode) > self:ArithmeticEvaluator(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.LESSER) then
        return self:ArithmeticEvaluator(CurrentNode.LeftNode) < self:ArithmeticEvaluator(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.EQUALS) then
        return (self:ArithmeticEvaluator(CurrentNode.LeftNode) == self:ArithmeticEvaluator(CurrentNode.RightNode))
    end
end

function CInterpreter:Interpret(Root)
    for i = 1, #Root do
        self:MainEvaluator(Root[i])
    end
end

function CInterpreter:Execute()
    local Root = self.Parser:Program()

    for i = 1, #Root do
        self.SymbolTable:Evaluate(Root[i])
    end

    self:Interpret(Root)
end

return { CInterpreter }