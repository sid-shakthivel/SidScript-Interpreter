local CInterpreter = require("src.Interpreter")[1]
local CLexer = require("src.Lexer")[1]

Program = "\z
START \z
num i = 0;\z
while i < 10 { \z
    if i == 5 { \z
        print i; \z
    } \z
    i = i + 1; \z
} \z
FINISH\z
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
--print(Lexer:GetNextToken().Value)
--print(Lexer:GetNextToken().Value)


