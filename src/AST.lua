CAST = {}
CAST.CBinaryNode = { Token, LeftNode, RightNode }

CAST.CProgramNode = { Children }

function CAST.CProgramNode:new()
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Children = {}
    self.__index = self
    return NewNode
end

function CAST.CBinaryNode:new(Token, LeftNode, RightNode)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = Token
    NewNode.LeftNode = LeftNode or nil
    NewNode.RightNode = RightNode or nil
    self.__index = self
    return NewNode
end

CAST.CUnaryNode = { Token, NextNode }

function CAST.CUnaryNode:new(Token, NextNode)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = Token
    NewNode.NextNode = NextNode
    self.__index = self
    return NewNode
end

CAST.CNode = { Token }

function CAST.CNode:new(Token)
    NewNode = {}
    setmetatable(NewNode, self)
    NewNode.Token = Token
    self.__index = self
    return NewNode
end

return CAST