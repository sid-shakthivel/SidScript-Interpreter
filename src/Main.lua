local CInterpreter = require("src.Interpreter")[1]

Program = " \z
START       \z
str x = `hello`;  \z
num y = 23; \z
if (x == `hello`) {  \z
    y = 0;  \z
}           \z
else {      \z
    y = 1;  \z
}           \z
FINISH      \z
"

Interpreter = CInterpreter:new(Program)
Interpreter:Execute()

--print(Interpreter.VariableTable["x"])
print(Interpreter.VariableTable["y"])
--print(Interpreter.VariableTable["z"])
