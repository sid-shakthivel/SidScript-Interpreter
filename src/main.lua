local CInterpreter = require("src.interpreter")[1]

Interpreter = CInterpreter:new("START str a = `hello world` FINISH")
Interpreter:Execute()

--print(Interpreter.VariableTable["test"])
--print(Interpreter.VariableTable["variable"])
--print(Interpreter.VariableTable["jim"])
