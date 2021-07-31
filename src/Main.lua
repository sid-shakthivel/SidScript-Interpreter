local CInterpreter = require("src.Interpreter")[1]

Interpreter = CInterpreter:new("START num myNumber = 72; FINISH")
Interpreter:Execute()

print(Interpreter.VariableTable["myNumber"])
--print(Interpreter.VariableTable["b"])
--print(Interpreter.VariableTable["jim"])
