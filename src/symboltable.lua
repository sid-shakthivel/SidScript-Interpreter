CSymbolTable = { Symbols = { }, Tokens, VariableTable }

CVariableSymbol = { Name, Value, Type }

function CVariableSymbol:new(Name, Type)
    NewVariableSymbol = {}
    setmetatable(NewVariableSymbol, self)
    NewVariableSymbol.Name = Name
    NewVariableSymbol.Type = Type
    self.__index = self
    return NewVariableSymbol
end

function CSymbolTable:new(Tokens, VariableTable)
    NewSymbolTable = {}
    setmetatable(NewSymbolTable, self)
    NewSymbolTable.Tokens = Tokens
    NewSymbolTable.VariableTable = VariableTable
    self.__index = self
    return NewSymbolTable
end

function CSymbolTable:SetSymbol(Name, Type)
    NewSymbol = CVariableSymbol:new(Name, Type)
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
        if (CurrentNode.LeftNode.Type == self.Tokens.ADD) then
            local Expr = self:ArithmeticEvaluator(CurrentNode.RightNode)
            if (tonumber(Expr) == false) then
                print("ERROR")
            end
        end
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        if ((self:GetSymbol(CurrentNode.Token.Value)) == nil) then
            print("ERROR")
        else
            return self:GetSymbol(CurrentNode.Token.Value)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.NUM) then
        local VariableNode = CurrentNode.NextNode.Token;
        self:SetSymbol(VariableNode.Value, VariableNode.Type)
        return self:GetSymbol(VariableNode.Value)
    end
end

function CSymbolTable:ArithmeticEvaluator(CurrentNode)
    if (CurrentNode == nil or CurrentNode.Token == nil) then
        return 0
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.ADD) then
        if (CurrentNode.NextNode) then
            return self:Interpret(CurrentNode.NextNode)
        else
            return self:Interpret(CurrentNode.LeftNode) + self:Interpret(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.MIN) then
        if (CurrentNode.NextNode) then
            return -self:Interpret(CurrentNode.NextNode)
        else
            return self:Interpret(CurrentNode.LeftNode) - self:Interpret(CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.MUL) then
        return self:Interpret(CurrentNode.LeftNode) * self:Interpret(CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.DIV) then
        return self:Interpret(CurrentNode.LeftNode) / self:Interpret(CurrentNode.RightNode)
    elseif (tonumber(CurrentNode.Token.Value)) then
        return tonumber(CurrentNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.VAR) then
        return self.VariableTable[CurrentNode.Token.Value].Expr
    elseif (CurrentNode.Token.Type == self.Lexer.Tokens.NUM) then
        return CurrentNode.NextNode.Token.Value
    end
end

return { CSymbolTable }