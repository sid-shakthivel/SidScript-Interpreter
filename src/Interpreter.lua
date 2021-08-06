local CLexer = require("src.Lexer")[1]
local CParser = require("src.Parser")[1]
local CSymbolTable = require("src.SymbolTable")[1]

CInterpreter = { Lexer, Parser, SymbolTable, Tokens }
CInterpreter.VariableTable = {}
CInterpreter.FunctionTable = {}

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

function CInterpreter:SetFunction(Name, Value)
    -- Value = AST
    self.VariableTable[Name] = Value
end

function CInterpreter:GetFunction(Name)
    return self.VariableTable[Name]
end

function CInterpreter:VariableEvaluator(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        local Variable = CurrentNode.LeftNode.Token.Value
        if (CurrentNode.LeftNode.NextNode) then
            Variable = self:VariableEvaluator(CurrentNode.LeftNode)
        end
        local Value = self:VariableEvaluator(CurrentNode.RightNode)
        self:SetVariable(Variable, Value)
        return self:GetVariable(Variable)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE or CurrentNode.Token.Type == self.Tokens.STR_TYPE or CurrentNode.Token.Type == self.Tokens.BOOL_TYPE) then
        return self:VariableEvaluator(CurrentNode.NextNode)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM or CurrentNode.Token.Type == self.Tokens.STR or CurrentNode.Token.Type == self.Tokens.BOOL) then
        return CurrentNode.Token.Value
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        if (self:GetVariable(CurrentNode.Token.Value) == nil) then
            return CurrentNode.Token.Value
        else
            return self:GetVariable(CurrentNode.Token.Value)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.MUL) then
        return self:VariableEvaluator(CurrentNode.RightNode) * self:VariableEvaluator(CurrentNode.LeftNode)
    elseif (CurrentNode.Token.Type == self.Tokens.MIN) then
        return self:VariableEvaluator(CurrentNode.RightNode) - self:VariableEvaluator(CurrentNode.LeftNode)
    elseif (CurrentNode.Token.Type == self.Tokens.DIV) then
        return self:VariableEvaluator(CurrentNode.RightNode) / self:VariableEvaluator(CurrentNode.LeftNode)
    elseif (CurrentNode.Token.Type == self.Tokens.ADD) then
        if (CurrentNode.NextNode) then
            return self:VariableEvaluator(CurrentNode.NextNode) + 1
        else
            return self:VariableEvaluator(CurrentNode.RightNode) + self:VariableEvaluator(CurrentNode.LeftNode)
        end
    end
    return 0
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
        return self:VariableEvaluator(CurrentNode.LeftNode) == self:VariableEvaluator(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.GREATER) then
        return self:VariableEvaluator(CurrentNode.LeftNode) > self:VariableEvaluator(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.LESSER) then
        return self:VariableEvaluator(CurrentNode.LeftNode) < self:VariableEvaluator(CurrentNode.RightNode)
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
        local Variable = self:VariableEvaluator(CurrentNode.LeftNode)
        while true do
            if (self:ConditionalEvaluator(CurrentNode.CentreLeftNode) == true) then
                self:Interpret(CurrentNode.RightNode)
            else
                break
            end
            self:SetVariable(Variable.Name, self:VariableEvaluator(CurrentNode.CentreRightNode))
        end
    end
    return 0
end

function CInterpreter:FunctionEvaluator(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.FUNC) then
        self:SetFunction(CurrentNode.CentreNode.Token.Value, CurrentNode)
    elseif (CurrentNode.Token.Type == self.Tokens.CALL) then
        local Function = self:GetFunction(CurrentNode.LeftNode.Token.Value)
        -- Parameters
        for i = 1, #Function.LeftNode do
            self:SetVariable(Function.LeftNode[i].Token.Value, self:VariableEvaluator(CurrentNode.RightNode[i]))
        end
        return self:Interpret(Function.RightNode)
    end
end

function CInterpreter:MainEvaluator(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        return self:VariableEvaluator(CurrentNode)
    elseif (CurrentNode.Token.Type == self.Tokens.IF) then
        return self:ConditionalEvaluator(CurrentNode)
    elseif (CurrentNode.Token.Type == self.Tokens.WHILE or CurrentNode.Token.Type == self.Tokens.FOR) then
        return self:IterativeEvaluator(CurrentNode)
    elseif (CurrentNode.Token.Type == self.Tokens.PRINT) then
        print(self:VariableEvaluator(CurrentNode.NextNode))
    elseif (CurrentNode.Token.Type == self.Tokens.FUNC or CurrentNode.Token.Type == self.Tokens.CALL) then
        return self:FunctionEvaluator(CurrentNode)
    end
    return 0
end

function CInterpreter:Interpret(Root)
    for i = 1, #Root do
        self:MainEvaluator(Root[i])
    end
end

function CInterpreter:Execute()
    local Root = self.Parser:Program()

    --print(Root[1].Token.Value)
    --print(Root[1].CentreNode.Token.Value)
    --print(#Root[1].LeftNode)
    --print(Root[1].RightNode[1].Token.Value)
    --print(Root[1].RightNode[1].NextNode.Token.Value)

    --print(Root[2].Token.Value)
    --print(Root[2].LeftNode.Token.Value)
    --print(#Root[2].RightNode)

    for i = 1, #Root do
        self.SymbolTable:Evaluate(Root[i])
    end

    self:Interpret(Root)
end

return { CInterpreter }