# SidScript 

SidScript interpreter written in Lua.

## Usage - Windows

`SidScriptInterpreter.exe [filename.txt]`

## Usage - MacOS

`src/SidScriptInterpreterMacOS.lua.lua [filename.txt]`

## Building Natively - Windows

```
gh repo clone sid-shakthivel/Interpreter
cd Interpreter-master
gh repo clone noahp/srlua-mingw
srlua-mingw-master\glue.exe srlua-mingw-master\srlua.exe src\SidScriptInterpreterWindows.lua SidScriptInterpreter.exe
```

## Building Natively - MacOS

```
brew install lua
gh repo clone sid-shakthivel/Interpreter
cd Interpreter-master
```

## SidScript - Overview

SidScript is a small language. SidScript syntax is meant to be intuitive and quick to write, essentially a hybrid of python and C. Below is both the BNF-based grammar and some examples.

## SidScript - Grammar

```
Program: Statements
Statements: (Statement SEMI)*
Statement: (IfElse | Assign | While | Print | For | Expr | FunctionDecleration | FunctionCall | Return) 
Print: PRINT Expr 

FunctionDecleration: (NUM_TYPE | STR_TYPE | BOOL_TYPE | VOID_TYPE) FUNC VAR LPAREN Parameters RPAREN RBRACE Statements LBRACE
FunctionCall: VAR LPAREN Parameters RPAREN
Return: RETURN Expr

Assign: (NUM_TYPE | STR_TYPE | BOOL_TYPE | LIST_TYPE) VAR ASSIGN Expr | VAR ASSIGN Expr
IfElse: IF Condition LBRACE Statements RBRACE | IF Condition LBRACE Statements RBRACE ELSE LBRACE Statements RBRACE
While: WHILE Condition LBRACE Statements RBRACE
For: FOR Assign SEMI Condition SEMI Expr LBRACE Statements RBRACE
Condition: Expr (EQUALS |GREATER | LESSER) Expr

ListMember: VAR LBRACKET NUM RBRACKET
ListLength: HASH VAR
ListPush: PUSH LPAREN VAR COMMA Value RPAREN
ListRemove: REMOVE LPAREN VAR COMMA Value RPAREN

Expr: Term ((ADD | MINUS) Term)*
Term: Value ((MUL | DIV) Value)*
Value: (MIN | ADD) NUM | LPAREN Expr RPAREN | NUM | BOOL | STR | (ADD) VAR | VAR | FunctionCall | LBRACKET Parameters RBRACKET | ListMember | ListLength

Parameters: Expr | (Expr COMMA)* | (NUM_TYPE | STR_TYPE | BOOL_TYPE) VAR | ((NUM_TYPE | STR_TYPE | BOOL_TYPE) VAR COMMA)*
```

## SidScript - Example Programs

### Variables

```
num test = 45;
str hello = `world`;
bool IsEpicProgramingLanguage = true;
list b = [1, 2, 3];
print IsEpicProgramingLanguage;
```

### Conditionals

```
num i = 45;
if i == 45 {
    print `yay`;
} else {
    print `nay`;
}
```

### While Loops

```
num i = 0;
while i < 10 {
    print i;
    i = i + 1;
}
```

### For Loops

```
for num i = 0; i < 10; +i {
    print i;
}
```

### Lists 

```
list numbers = [1, 2, 3];
push(numbers, 45);
print numbers[4];
remove(numbers, 4);
```

```
list a = [1, 2, 3];
for num i = 1; i < #a; +i {
    print a[i];
}
```

Note the following:\
- Lists can only contain the num type
- `# [ListName]` Returns the length of the list plus one

### Functions

```
num func test (num bar) {
    return bar + 4;
}
print test(4);
```

### Recursion

```
num func factorial (num number) {
    if number == 0 {
        return 1;
    } else {
        return number * factorial (number -1);
    }
}

print factorial (5);
```



