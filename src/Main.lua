local CInterpreter = require("src.Interpreter")[1]
local CLexer = require("src.Lexer")[1]

Program1 = "\z
START \z
num i = 0;\z
while i < 10 {\z
    if i == 4 {\z
        print i;\z
    }\z
    i = i + 1;\z
}\z
print `hey`;\z
FINISH\z
"

Program = "\z
START \z
func foo () {\z
    print `bar`;\z
}\z
foo ();\z
FINISH\z
"

Interpreter = CInterpreter:new(Program)
Interpreter:Execute()


