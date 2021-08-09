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


CSymbolTable = { Symbols = { }, ScopeName, ScopeLevel }

function CSymbolTable:new(ScopeName, ScopeLevel)
    NewSymbolTable = {}
    setmetatable(NewSymbolTable, self)
    NewSymbolTable.ScopeName = ScopeName
    NewSymbolTable.ScopeLevel = ScopeLevel
    self.__index = self
    return NewSymbolTable
end

function CSymbolTable:SetSymbol(Name, Type, Category, Parameters)
    local Case =
    {
        ["Variable"] = function()
            return CSymbol:new(Name, Type)
        end,
        ["Function"] = function()
            return CFunctionSymbol:new(Name, Type, Parameters)
        end
    }
    NewSymbol = Case[Category]()
    self.Symbols[Name] = NewSymbol
end

function CSymbolTable:GetSymbol(Name)
    return self.Symbols[Name]
end

CSemanticAnalyser = { Tokens, Scope }

function CSemanticAnalyser:new(Tokens)
    NewSemanticAnalyser = {}
    setmetatable(NewSemanticAnalyser, self)
    NewSemanticAnalyser.Tokens = Tokens
    NewSemanticAnalyser.Scope = CSymbolTable:new("Global", 1)
    self.__index = self
    return NewSemanticAnalyser
end

return { CSemanticAnalyser }