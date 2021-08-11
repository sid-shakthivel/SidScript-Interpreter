local Error = require("src.Error")

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


-- ADD AN EXPR CHECKER TO MAKE SURE ALL EXPR WORK PROPERLY EG YOU CAN'T ADD STRINGS
--  COMPARE CONDITIONS (MAKE SURE THEY ARE OF THE SAME TYPE)
function CSemanticAnalyser:Analyse(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.FUNC) then
        local NewSymbol = CFunctionSymbol:new(CurrentNode.CentreLeftNode.Token.Value, CurrentNode.Token.Type, CurrentNode.LeftNode)
        self.CurrentScope:SetSymbol(NewSymbol)
        self:BuildSymbolTable(CurrentNode.CentreLeftNode.Token.Value, ConcatenateTable(CurrentNode.LeftNode, CurrentNode.RightNode))
    elseif (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        return self:Analyse(CurrentNode.LeftNode)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE or CurrentNode.Token.Type == self.Tokens.STR_TYPE or CurrentNode.Token.Type == self.Tokens.BOOL_TYPE) then
        if (self.CurrentScope:GetSymbol(CurrentNode.NextNode.Token.Value) ~= nil) then
            Error:Error("SEMANTIC ERROR: VARIABLE " .. CurrentNode.NextNode.Token.Value .. " ALREADY DECLARED")
        end
        local NewSymbol = CSymbol:new(CurrentNode.NextNode.Token.Value, CurrentNode.Token.Type)
        self.CurrentScope:SetSymbol(NewSymbol)
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        if (self.CurrentScope:GetSymbol(CurrentNode.Token.Value) == nil) then
            Error:Error("SEMANTIC ERROR: VARIABLE " .. CurrentNode.Token.Value .. " NOT DECLARED ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.CALL) then
        local Function = self.CurrentScope:GetSymbol(CurrentNode.LeftNode.Token.Value)
        -- COMPARE TYPES OF PARAMETERS
        if (#Function.Parameters ~= #CurrentNode.RightNode) then
            Error:Error("SEMANTIC ERROR: INSUFFICIENT ARGUMENTS PASSED TO FUNCTION " .. Function.CentreLeftNode.Token.Value)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.IF) then
        self.CurrentScope = NewSymbolTable.EnclosingScope
        self:BuildSymbolTable(("if " .. math.random(1000000)), CurrentNode.LeftNode)
        if (CurrentNode.RightNode ~= nil) then
            self:BuildSymbolTable(("else " .. math.random(1000000)), CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.WHILE) then
        self:BuildSymbolTable(("while " .. math.random(1000000)), CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.FOR) then
        self:Analyse(CSymbolTable.LeftNode)
        self:BuildSymbolTable(("for " .. math.random(1000000)), CurrentNode.RightNode)
    end
end

function CSemanticAnalyser:BuildSymbolTable(Name, Body)
    local NewScope = CSymbolTable:new(Name, self.CurrentScope)
    self.CurrentScope = NewScope
    for i = 0, #Body do
        self:Analyse(Body[i])
    end
    self.CurrentScope = NewScope.EnclosingScope
end

function ConcatenateTable(Table1, Table2)
    for i = 1, #Table2 do
        Table1[#Table1+1] = Table2[i]
    end
    return Table1
end


return { CSemanticAnalyser }