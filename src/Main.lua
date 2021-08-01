local CInterpreter = require("src.Interpreter")[1]
local CLexer = require("src.Lexer")[1]

Program = " \z
START       \z
num x = 3;  \z
num y = 23; \z
if (x > 5) {  \z
    y = 0;  \z
}           \z
else {      \z
    y = 1;  \z
}           \z
FINISH      \z
"

Interpreter = CInterpreter:new(Program)
Interpreter:Execute()

print("X IS " .. Interpreter.VariableTable["x"])
print("Y IS " .. Interpreter.VariableTable["y"])
