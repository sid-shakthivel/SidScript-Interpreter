CSymbol = { Name, Type, Scope }

function CSymbol:new(Name, Type)
    NewSymbol = {}
    setmetatable(NewSymbol, self)
    NewSymbol.Name = Name
    NewSymbol.Type = Type
    self.__index = self
    return NewSymbol
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
        error("ERROR: VARIABLE " .. Name .. " NOT FOUND")
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
        local NewSymbol = CSymbol:new(CurrentNode.CentreLeftNode.Token.Value, CurrentNode.Token.Type)
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
        local NewSymbol = CSymbol:new(CurrentNode.LeftNode.NextNode.Token.Value, CurrentNode.LeftNode.Token.Type)
        self.CurrentScope:SetSymbol(NewSymbol)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE) then
        local NewSymbol = CSymbol:new(CurrentNode.NextNode.Token.Value, CurrentNode.Token.Type)
        self.CurrentScope:SetSymbol(NewSymbol)
    end
end

return { CSemanticAnalyser }