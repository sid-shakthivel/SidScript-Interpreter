local CInterpreter = require("src.Interpreter")[1]
local CLexer = require("src.Lexer")[1]

local File = io.open("./programs/program1.txt", "r")
local Program = ""
local CurrentLine = File:read("*line")

while CurrentLine ~= nil do
    Program = Program .. "\n" .. CurrentLine
    CurrentLine = File:read("*line")
    if (CurrentLine ~= nil  and CurrentLine:sub(1, 1) == '#') then
        CurrentLine = File:read("*line")
    end
end

File:close()

Interpreter = CInterpreter:new(Program)
Interpreter:Execute()

--Lexer = CLexer:new(Program)
--Lexer:InvertTokens()
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)