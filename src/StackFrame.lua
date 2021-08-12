CStackFrame = { Name, EncapsulatingScope, Members }

function CStackFrame:new(Name, EncapsulatingScope)
    NewStackFrame = {}
    setmetatable(NewStackFrame, self)
    NewStackFrame.Name = Name
    NewStackFrame.EncapsulatingScope = EncapsulatingScope
    NewStackFrame.Members = {}
    self.__index = self
    return NewStackFrame
end

function CStackFrame:SetItem(Key, Value)
    self.Members[Key] = Value
end

function CStackFrame:SetListItem(Key, Index, Value)
    self.Members[Key][Index].Token.Value = Value
end

function CStackFrame:GetItem(Key)
    if (self.Members[Key] ~= nil) then
        return self.Members[Key]
    elseif (self.Members[Key] == nil and self.EncapsulatingScope ~= nil) then
        return self.EncapsulatingScope:GetItem(Key)
    else
        return nil
    end
end

return { CStackFrame }
