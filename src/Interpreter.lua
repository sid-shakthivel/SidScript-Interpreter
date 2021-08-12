local CLexer = require("src.Lexer")[1]
local CParser = require("src.Parser")[1]
local CSemanticAnalyser = require("src.SemanticAnalyser")[1]
local CStack = require("src.Stack")[1]
local CSTackFrame = require("src.StackFrame")[1]

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
            return self:ExpressionAssignmentEvaluator(self.CallStack:Peek():GetItem(CurrentNode.Token.Value)[CurrentNode.NextNode.Token.Value])
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
        local NewStackFrame = CSTackFrame:new(CurrentNode.LeftNode.Token.Value, self.CallStack:Peek())
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
        return self:ExpressionAssignmentEvaluator(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.REMOVE) then
        local ListName = CurrentNode.LeftNode.Token.Value
        table.remove(self.CallStack:Peek():GetItem(ListName), self:ExpressionAssignmentEvaluator(CurrentNode.RightNode))
    elseif (CurrentNode.Token.Type == self.Tokens.HASH) then
        local ListName = CurrentNode.NextNode.Token.Value
        return #(self.CallStack:Peek():GetItem(ListName))
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

    self.CallStack:Push(CSTackFrame:new("Main", nil))
    --self:Interpret(Root)
    self.CallStack:Pop()
end

return { CInterpreter }