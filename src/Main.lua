local CInterpreter = require("src.Interpreter")[1]
--local CLexer = require("src.Lexer")[1]

local File = io.open("./programs/program1.txt", "r")
local Program = ""
local CurrentLine = File:read("*line")

while CurrentLine ~= nil do
    Program = Program .. " " .. CurrentLine
    CurrentLine = File:read("*line")
end

File:close()

Interpreter = CInterpreter:new(Program)
Interpreter:Execute()


