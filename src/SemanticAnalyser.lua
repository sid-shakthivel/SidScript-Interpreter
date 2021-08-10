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

CSemanticAnalyser = { Tokens, CurrentScope, GlobalScope, Scopes }

function CSemanticAnalyser:new(Tokens)
    NewSemanticAnalyser = {}
    setmetatable(NewSemanticAnalyser, self)
    NewSemanticAnalyser.Tokens = Tokens
    NewSemanticAnalyser.GlobalScope = CSymbolTable:new("Global", nil)
    NewSemanticAnalyser.CurrentScope = NewSemanticAnalyser.GlobalScope
    NewSemanticAnalyser.Scopes = {}
    self.__index = self
    return NewSemanticAnalyser
end

function CSemanticAnalyser:BuildSymbolTables(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.FUNC) then
        local NewSymbol = CFunctionSymbol:new(CurrentNode.CentreLeftNode.Token.Value, CurrentNode.Token.Type, CurrentNode.LeftNode)
        self.CurrentScope:SetSymbol(NewSymbol)
        local NewSymbolTable = CSymbolTable:new(CurrentNode.CentreLeftNode.Token.Value, self.CurrentScope)
        self.CurrentScope = NewSymbolTable
        for i = 1, #CurrentNode.LeftNode do
            self:BuildSymbolTables(CurrentNode.LeftNode[i])
        end
        for i = 1, #CurrentNode.RightNode do
            self:BuildSymbolTables(CurrentNode.RightNode[i])
        end
        table.insert(self.Scopes, self.CurrentScope)
        self.CurrentScope = self.CurrentScope.EnclosingScope
    elseif (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        return self:BuildSymbolTables(CurrentNode.LeftNode)
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
        if (#Function.Parameters ~= #CurrentNode.RightNode) then
            Error:Error("SEMANTIC ERROR: INSUFFICIENT ARGUMENTS PASSED TO FUNCTION " .. Function.CentreLeftNode.Token.Value)
        end
        for i = 1, #CurrentNode.RightNode do
            self:BuildSymbolTables(CurrentNode.RightNode[i])
        end
    end
end

return { CSemanticAnalyser }