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
    elseif (Category == "NUMBER") then
    end
    self.Symbols[Name] = NewSymbol
end

function CSymbolTable:GetSymbol(Name)
    return self.Symbols[Name]
end

function CSymbolTable:BuildSymbolTable(CurrentNode)
    if (CurrentNode == nil or CurrentNode.Token == nil) then
        return 0
    elseif (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        local Variable =  self:BuildSymbolTable(CurrentNode.LeftNode)
        local Expr = self:BuildSymbolTable(CurrentNode.RightNode)
        if (Expr.Type ~= self.Tokens.NUM) then
            print("ERROR")
        end
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        if ((self:GetSymbol(CurrentNode.Token.Value)) == nil) then
            error("ERROR: VARIABLE NOT DECLARED")
        else
            return self:GetSymbol(CurrentNode.Token.Value)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.NUM) then
        local VariableNode = CurrentNode.NextNode.Token;
        self:SetSymbol(VariableNode.Value, self.Tokens.NUM, "VARIABLE")
        return self:GetSymbol(VariableNode.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.ADD or CurrentNode.Token.Type == self.Tokens.MUL or CurrentNode.Token.Type == self.Tokens.MIN or CurrentNode.Token.Type == self.Tokens.DIV) then
        local LeftSide = self:BuildSymbolTable(CurrentNode.LeftNode)
        local RightSide = self:BuildSymbolTable(CurrentNode.LeftNode)
        if (LeftSide.Type == self.Tokens.NUM and RightSide.Type == self.Tokens.NUM) then
            return LeftSide
        else
            return { Name = nil, Type = self.Tokens.EOF }
        end
    elseif (CurrentNode.Token.Type == self.Tokens.INTEGER) then
        local VariableNode = CurrentNode.Token
        self:SetSymbol(VariableNode.Value, self.Tokens.NUM, "NUMBER")
        return self:GetSymbol(VariableNode.Value)
    end
end

return { CSymbolTable }