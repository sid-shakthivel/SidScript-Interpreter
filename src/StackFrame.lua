CStackFrame = { Name, ScopeLevel, Members }

function CStackFrame:new(Name, ScopeLevel)
    NewStackFrame = {}
    setmetatable(NewStackFrame, self)
    NewStackFrame.Name = Name
    NewStackFrame.ScopeLevel = ScopeLevel
    NewStackFrame.Members = {}
    self.__index = self
    return NewStackFrame
end

function CStackFrame:SetItem(Key, Value)
    self.Members[Key] = Value
end

function CStackFrame:GetItem(Key)
    return self.Members[Key]
end

return { CStackFrame }
