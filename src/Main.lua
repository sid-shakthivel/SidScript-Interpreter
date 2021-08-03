local CInterpreter = require("src.Interpreter")[1]
local CLexer = require("src.Lexer")[1]

Program = "\z
START \z
for num i = 0; i < 10; ++i { \z
    print i; \z
} \z
FINISH \z
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


--print(Interpreter.VariableTable["i"])
--print(Interpreter.VariableTable["y"])
--print(Interpreter.VariableTable["z"])
