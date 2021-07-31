local CInterpreter = require("src.interpreter")[1]

Interpreter = CInterpreter:new("START num test = 4*5; num variable = 45; num jim = variable + test; FINISH")
Interpreter:Execute()

print(Interpreter.VariableTable["test"])
print(Interpreter.VariableTable["variable"])
print(Interpreter.VariableTable["jim"])
