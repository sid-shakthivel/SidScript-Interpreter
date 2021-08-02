local CInterpreter = require("src.Interpreter")[1]

Program1 = " \z
START       \z
bool x = false;  \z
num y = 23; \z
if (x == false) {  \z
    y = 0;  \z
    print(y); \z
}           \z
else {      \z
    y = 1;  \z
}           \z
FINISH      \z
"

Program = " \z
START       \z
print 4*5; \z
FINISH      \z
"

Interpreter = CInterpreter:new(Program)
Interpreter:Execute()

--Lexer = CLexer:new(Program)
--print(Lexer:GetNextToken().Type)
--print(Lexer:GetNextToken().Type)
--print(Lexer:GetNextToken().Type)
--print(Lexer:GetNextToken().Type)
--print(Lexer:GetNextToken().Type)

--print(Interpreter.VariableTable["x"])
--print(Interpreter.VariableTable["y"])
--print(Interpreter.VariableTable["z"])
