CVariableSymbol = { Name, Type }

function CVariableSymbol:new(Name, Type)
    NewVariableSymbol = {}
    setmetatable(NewVariableSymbol, self)
    NewVariableSymbol.Name = Name
    NewVariableSymbol.Type = Type
    self.__index = self
    return NewVariableSymbol
end

CBuiltInSymbol = { Name, Type }

function CBuiltInSymbol:new(Name, Type)
    NewBuiltInSymbol = {}
    setmetatable(NewBuiltInSymbol, self)
    NewBuiltInSymbol.Name = Name
    NewBuiltInSymbol.Type = Type
    self.__index = self
    return NewBuiltInSymbol
end

CSymbolTable = { Symbols = { }, Tokens, VariableTable }

function CSymbolTable:new(Tokens, VariableTable)
    NewSymbolTable = {}
    setmetatable(NewSymbolTable, self)
    NewSymbolTable.Tokens = Tokens
    NewSymbolTable.VariableTable = VariableTable
    self.__index = self
    return NewSymbolTable
end

function CSymbolTable:SetSymbol(Name, Type, Category)
    if (Category == "VARIABLE") then
        NewSymbol = CVariableSymbol:new(Name, Type)
    else
        NewSymbol = CBuiltInSymbol:new(Name, Type)
    end
    self.Symbols[Name] = NewSymbol
end

-- Checks for semantic error eg variable not declared
function CSymbolTable:Evaluate(CurrentNode, CurrentType)
    if (CurrentNode == nil  or CurrentNode.Token == false) then
        return 0
    elseif (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        local Variable =  self:Evaluate(CurrentNode.LeftNode)
        local Value = self:Evaluate(CurrentNode.RightNode)
        if (Value.Type ~= Variable.Type) then
            error("ERROR: INITIALISING VARIABLE WITH INCOMPATIBLE TYPE")
        else
            return 0
        end
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE or CurrentNode.Token.Type == self.Tokens.STR_TYPE or CurrentNode.Token.Type == self.Tokens.BOOL_TYPE) then
        local Variable = CurrentNode.NextNode.Token
        self:SetSymbol(Variable.Value, CurrentNode.Token.Type, "VARIABLE")
        return self:GetSymbol(Variable.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.ADD or CurrentNode.Token.Type == self.Tokens.MUL or CurrentNode.Token.Type == self.Tokens.MIN or CurrentNode.Token.Type == self.Tokens.DIV) then
        local LeftNode = self:Evaluate(CurrentNode)
        local RightNode = self:Evaluate(RightNode)
        if (LeftNode.Type ~= NUM or RightNode.Type ~= NUM) then
            error("ERROR: INITIALISING VARIABLE WITH INCOMPATIBLE TYPE")
        else
            return RightNode
        end
    elseif (CurrentNode.Token.Type == self.Tokens.STR) then
        local Variable = CurrentNode.Token
        self:SetSymbol(Variable.Value, self.Tokens.STR_TYPE, "STRING")
        return self:GetSymbol(Variable.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM) then
        local Variable = CurrentNode.Token
        self:SetSymbol(Variable.Value, self.Tokens.NUM_TYPE, "NUMBER")
        return self:GetSymbol(Variable.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.BOOL) then
        local Variable = CurrentNode.Token
        self:SetSymbol(Variable.Value, self.Tokens.BOOL_TYPE, "BOOLEAN")
        return self:GetSymbol(Variable.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        local Variable = self:GetSymbol(CurrentNode.Token.Value)
        if (Variable == nil) then
            error("ERROR: VARIABLE " .. CurrentNode.Token.Value .. " NOT DECLARED")
        else
            return Variable
        end
    end
end

function CSymbolTable:GetSymbol(Name)
    return self.Symbols[Name]
end

return { CSymbolTable }