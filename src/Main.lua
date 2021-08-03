local CInterpreter = require("src.Interpreter")[1]
local CLexer = require("src.Lexer")[1]

Program = "\z
START \z
print `hello`; \z
FINISH \z
"

Interpreter = CInterpreter:new(Program)
Interpreter:Execute()
