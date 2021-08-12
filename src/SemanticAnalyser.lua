local Error = require("src.Error")

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

function CSemanticAnalyser:Analyse(CurrentNode)
    if (CurrentNode.Token.Type == self.Tokens.FUNC) then
        if (self.CurrentScope:GetSymbol(CurrentNode.CentreLeftNode.Token.Value) ~= nil) then
            Error:Error("SEMANTIC ERROR: FUNCTION OF NAME " .. CurrentNode.CentreLeftNode.Token.Value .. " ALREADY DECLARED")
        end
        for i = 1, #CurrentNode.LeftNode do
            self:GetFormattedVariableType(CurrentNode.LeftNode[i].Token)
        end
        local NewSymbol = CFunctionSymbol:new(CurrentNode.CentreLeftNode.Token.Value, self:GetFormattedVariableType(CurrentNode.CentreRightNode.Token), CurrentNode.LeftNode)
        self.CurrentScope:SetSymbol(NewSymbol)
        self:BuildSymbolTable(CurrentNode.CentreLeftNode.Token.Value, ConcatenateTable(CurrentNode.LeftNode, CurrentNode.RightNode))
    elseif (CurrentNode.Token.Type == self.Tokens.CALL) then
        local Function = self.CurrentScope:GetSymbol(CurrentNode.LeftNode.Token.Value)
        if (Function == nil) then
            Error:Error("SEMANTIC ERROR: NO FUNCTION OF NAME " .. CurrentNode.LeftNode.Token.Value)
        end
        if (#Function.Parameters ~= #CurrentNode.RightNode) then
            Error:Error("SEMANTIC ERROR: INSUFFICIENT ARGUMENTS PASSED TO FUNCTION " .. Function.Name)
        end
        for i = 1, #Function.Parameters do
            if (self:GetType(CurrentNode.RightNode[i]) == nil or self:GetFormattedVariableType(Function.Parameters[i].Token) ~= self:GetType(CurrentNode.RightNode[i]).Type) then
                Error:Error("SEMANTIC ERROR: ARGUMENTS TYPES MUST MATCH FUNCTION PARAMETERS TYPES ON LINE " .. CurrentNode.LeftNode.Token.LineNumber)
            end
        end
    elseif (CurrentNode.Token.Type == self.Tokens.RETURN) then
        if (self.CurrentScope.Name == "Global") then
            Error:Error("SEMANTIC ERROR: RETURN MUST BE CALLED IN FUNCTION ON LINE " .. CurrentNode.Token.LineNumber)
        end
        local Function = self.CurrentScope.EnclosingScope:GetSymbol(self.CurrentScope.Name)
        if (Function.Type == self.Tokens.VOID) then
            Error:Error("SEMANTIC ERROR: VOID FUNCTIONS CANNOT RETURN VALUES ON LINE ".. CurrentNode.Token.LineNumber)
        end
        local ReturnType = self:GetType(CurrentNode.NextNode)
        if (Function.Type ~= ReturnType.Type) then
            Error:Error("SEMANTIC ERROR: " .. Function.Type .. " FUNCTIONS CANNOT RETURN " .. ReturnType.Type .. " ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.ASSIGN) then
        local LeftSide = self:Analyse(CurrentNode.LeftNode)
        local RightSide = self:GetType(CurrentNode.RightNode)

        if (LeftSide.Type == self.Tokens.LIST_TYPE) then
            local NewListSymbol = CListSymbol:new(CurrentNode.LeftNode.NextNode.Token.Value, self.Tokens.LIST, CurrentNode.RightNode.NextNode)
            self.CurrentScope:SetSymbol(NewListSymbol)
            LeftSide = self.CurrentScope:GetSymbol(CurrentNode.LeftNode.NextNode.Token.Value)
        end

        if ((RightSide ~= nil and LeftSide.Type ~= RightSide.Type) and LeftSide.Type ~= self.Tokens.LIST) then
            Error:Error("SEMANTIC ERROR: VARIABLE OF TYPE " .. LeftSide.Type .. " CAN'T BE ASSIGNED TO " .. RightSide.Type .. " ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        if (self.CurrentScope:GetSymbol(CurrentNode.Token.Value) == nil) then
            Error:Error("SEMANTIC ERROR: VARIABLE " .. CurrentNode.Token.Value .. " NOT DECLARED ON LINE " .. CurrentNode.Token.LineNumber)
        else
            return self.CurrentScope:GetSymbol(CurrentNode.Token.Value)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE or CurrentNode.Token.Type == self.Tokens.STR_TYPE or CurrentNode.Token.Type == self.Tokens.BOOL_TYPE) then
        if (self.CurrentScope:GetSymbol(CurrentNode.NextNode.Token.Value) ~= nil) then
            Error:Error("SEMANTIC ERROR: VARIABLE " .. CurrentNode.NextNode.Token.Value .. " ALREADY DECLARED")
        end
        local NewSymbol = CSymbol:new(CurrentNode.NextNode.Token.Value, self:GetFormattedVariableType(CurrentNode.Token))
        self.CurrentScope:SetSymbol(NewSymbol)
        return self.CurrentScope:GetSymbol(CurrentNode.NextNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.LIST_TYPE) then
        if (self.CurrentScope:GetSymbol(CurrentNode.NextNode.Token.Value) ~= nil) then
            Error:Error("SEMANTIC ERROR: VARIABLE " .. CurrentNode.NextNode.Token.Value .. " ALREADY DECLARED")
        end
        return CurrentNode.Token
    elseif (CurrentNode.Token.Type == self.Tokens.LIST) then
        local List = self.CurrentScope:GetSymbol(CurrentNode.Token.Value)
        if (List == nil) then
            Error:Error("SEMANTIC ERROR: LIST OF NAME " .. CurrentNode.Token.Value .. " NOT DECLARED")
        end
        if (List.Type ~= self.Tokens.LIST) then
            Error:Error("SEMANTIC ERROR: CANNOT INDEX NON-LIST ON LINE " .. CurrentNode.Token.LineNumber)
        end
        return CurrentNode.Token
    elseif (CurrentNode.Token.Type == self.Tokens.IF) then
        self:Analyse(CurrentNode.CentreNode)
        self.CurrentScope = NewSymbolTable.EnclosingScope
        self:BuildSymbolTable(("if " .. math.random(1000000)), CurrentNode.LeftNode)
        if (CurrentNode.RightNode ~= nil) then
            self:BuildSymbolTable(("else " .. math.random(1000000)), CurrentNode.RightNode)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.WHILE) then
        self:Analyse(CurrentNode.LeftNode)
        self:BuildSymbolTable(("while " .. math.random(1000000)), CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.FOR) then
        self:Analyse(CurrentNode.LeftNode)
        self:Analyse(CurrentNode.CentreLeftNode)
        self:BuildSymbolTable(("for " .. math.random(1000000)), CurrentNode.RightNode)
    elseif (CurrentNode.Token.Type == self.Tokens.LESSER or CurrentNode.Token.Type == self.Tokens.GREATER or CurrentNode.Token.Type == self.Tokens.EQUALS) then
        if (self:GetType(CurrentNode.LeftNode).Type ~= self:GetType(CurrentNode.RightNode).Type) then
            Error:Error("SEMANTIC ERROR: COMPARISON OF DIFFERENT TYPES ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.PUSH or CurrentNode.Token.Type == self.Tokens.REMOVE) then
        local List = self.CurrentScope:GetSymbol(CurrentNode.LeftNode.Token.Value)
        if (List == nil) then
            Error:Error("SEMANTIC ERROR: LIST OF NAME " .. CurrentNode.LeftNode.Token.Value .. " NOT DECLARED")
        elseif (List.Type ~= self.Tokens.LIST) then
            Error:Error("SEMANTIC ERROR: CANNOT USE LIST OPERATION ON NON-LIST " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.PRINT) then
        self:GetType(CurrentNode.NextNode)
    end
end

function CSemanticAnalyser:BuildSymbolTable(Name, Body)
    local NewScope = CSymbolTable:new(Name, self.CurrentScope)
    self.CurrentScope = NewScope
    for i = 1, #Body do
        self:Analyse(Body[i])
    end
    self.CurrentScope = NewScope.EnclosingScope
end

function CSemanticAnalyser:GetFormattedVariableType(Token)
    if (Token.Type == self.Tokens.NUM_TYPE) then
        return self.Tokens.NUM
    elseif (Token.Type == self.Tokens.STR_TYPE) then
        return self.Tokens.STR
    elseif (Token.Type == self.Tokens.BOOL_TYPE) then
        return self.Tokens.BOOL
    elseif (Token.Type == self.Tokens.VOID_TYPE) then
        return self.Tokens.VOID
    elseif (Token.Type == self.Tokens.LIST_TYPE) then
        return self.Tokens.LIST
    else
        Error:Error("SEMANTIC ERROR: UNEXPECTED IDENTIFIER " .. Token.Value)
    end
end

function CSemanticAnalyser:GetType(CurrentNode)
    if (CurrentNode == nil) then
        return nil
    elseif (CurrentNode.Token.Type == self.Tokens.NUM_TYPE or CurrentNode.Token.Type == self.Tokens.STR_TYPE or CurrentNode.Token.Type == self.Tokens.BOOL_TYPE) then
        return self:GetType(CurrentNode.NextNode)
    elseif (CurrentNode.Token.Type == self.Tokens.VAR) then
        return self.CurrentScope:GetSymbol(CurrentNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.NUM or CurrentNode.Token.Type == self.Tokens.STR or CurrentNode.Token.Type == self.Tokens.BOOL) then
        return CurrentNode.Token
    elseif (CurrentNode.Token.Type == self.Tokens.MUL) then
        if (self:GetType(CurrentNode.RightNode).Type == self.Tokens.NUM and self:GetType(CurrentNode.LeftNode)) then
            return self:GetType(CurrentNode.RightNode)
        else
            Error:Error("SEMANTIC ERROR: MULTIPLICATION OF NON NUMBERS ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.MIN) then
        if (self:GetType(CurrentNode.RightNode).Type == self.Tokens.NUM and self:GetType(CurrentNode.LeftNode)) then
            return self:GetType(CurrentNode.RightNode)
        else
            Error:Error("SEMANTIC ERROR: SUBTRACTION OF NON NUMBERS ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.DIV) then
        if (self:GetType(CurrentNode.RightNode).Type == self.Tokens.NUM and self:GetType(CurrentNode.LeftNode)) then
            return self:GetType(CurrentNode.RightNode)
        else
            Error:Error("SEMANTIC ERROR: DIVISION OF NON NUMBERS ON LINE " .. CurrentNode.Token.LineNumber)
        end
    elseif (CurrentNode.Token.Type == self.Tokens.ADD) then
        if (CurrentNode.NextNode) then
            if (self:GetType(CurrentNode.NextNode).Type == self.Tokens.NUM) then
                return self:GetType(CurrentNode.NextNode)
            else
                Error:Error("SEMANTIC ERROR: ADDITION OF NON NUMBERS ON LINE " .. CurrentNode.Token.LineNumber)
            end
        else
            if (self:GetType(CurrentNode.RightNode).Type == self.Tokens.NUM and self:GetType(CurrentNode.LeftNode)) then
                return self:GetType(CurrentNode.RightNode)
            else
                Error:Error("SEMANTIC ERROR: ADDITION OF NON NUMBERS ON LINE " .. CurrentNode.Token.LineNumber)
            end
        end
    elseif (CurrentNode.Token.Type == self.Tokens.CALL) then
        return self.CurrentScope:GetSymbol(CurrentNode.LeftNode.Token.Value)
    elseif (CurrentNode.Token.Type == self.Tokens.HASH) then
        local List = self.CurrentScope:GetSymbol(CurrentNode.NextNode.Token.Value)
        if (List == nil) then
            Error:Error("SEMANTIC ERROR: LIST OF NAME " .. CurrentNode.NextNode.Token.Value .. " NOT DECLARED")
        elseif (List.Type ~= self.Tokens.LIST) then
            Error:Error("SEMANTIC ERROR: CANNOT USE LIST OPERATION ON NON-LIST" .. CurrentNode.Token.LineNumber)
        else
            return { Type = self.Tokens.NUM }
        end
    elseif (CurrentNode.Token.Type == self.Tokens.LIST) then
        if (CurrentNode.NextNode.Token) then
            local Index = CurrentNode.NextNode.Token.Value
            local List = self.CurrentScope:GetSymbol(CurrentNode.Token.Value)
            if (List == nil) then
                Error:Error("SEMANTIC ERROR: LIST OF NAME " .. CurrentNode.Token.Value .. " NOT DECLARED")
            elseif (Index > #List.Members or Index < 1) then
                Error:Error("SEMANTIC ERROR: LIST " .. List.Name .. " OUT OF BOUNDS")
            elseif (List.Type ~= self.Tokens.LIST) then
                Error:Error("SEMANTIC ERROR: CANNOT INDEX NON-LIST ON LINE " .. CurrentNode.Token.LineNumber)
            else
                return List.Members[CurrentNode.NextNode.Token.Value].Token
            end
        else
            return CurrentNode.Token
        end
    end
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

CListSymbol = { Name, Type, Members }

function CListSymbol:new(Name, Type, Members)
    NewListSymbol = {}
    setmetatable(NewListSymbol, self)
    NewListSymbol.Name = Name
    NewListSymbol.Type = Type
    NewListSymbol.Members = Members
    self.__index = self
    return NewListSymbol
end

function ConcatenateTable(Table1, Table2)
    local NewTable = {}
    for i = 1, #Table1 do
        NewTable[i] = Table1[i]
    end
    for i = 1, #Table2 do
        NewTable[#Table1+i] = Table2[i]
    end
    return NewTable
end

return { CSemanticAnalyser }