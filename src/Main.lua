local CInterpreter = require("src.Interpreter")[1]
local CLexer = require("src.Lexer")[1]

Program1 = " \z
START       \z
num i = 1; \z
while i < 10 { \z
    print i; \z
    i = i + 1; \z
} \z
FINISH      \z
"

Program = " \z
START       \z
num i = 1; \z
while i < 10 { \z
    print i; \z
    i = i + 1; \z
} \z
FINISH      \z
"

Interpreter = CInterpreter:new(Program)
Interpreter:Execute()

--Lexer = CLexer:new(Program)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)

--print(Interpreter.VariableTable["i"])
--print(Interpreter.VariableTable["y"])
--print(Interpreter.VariableTable["z"])
