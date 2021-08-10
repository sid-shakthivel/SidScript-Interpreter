CStack = { StackFrames }

function CStack:new()
    NewStack = {}
    setmetatable(NewStack, self)
    NewStack.StackFrames = {}
    self.__index = self
    return NewStack
end

function CStack:Push(NewStackFrame)
    return table.insert(self.StackFrames, NewStackFrame)
end

function CStack:Pop()
    return table.remove(self.StackFrames)
end

function CStack:Peek()
    return self.StackFrames[#self.StackFrames]
end

return { CStack }