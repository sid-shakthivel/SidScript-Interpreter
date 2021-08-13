
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------

do
    local searchers = package.searchers or package.loaders
    local origin_seacher = searchers[2]
    searchers[2] = function(path)
        local files =
        {
------------------------
-- Modules part begin --
------------------------

----------------------
-- Modules part end --
----------------------
        }
        if files[path] then
            return files[path]
        else
            return origin_seacher(path)
        end
    end
end
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------
local CInterpreter = require("src.Interpreter")[1]
local Error = require("src.Error")

local FileName = arg[1]

if (FileName == nil) then
    Error:Error("FILE ERROR: FILE NOT GIVEN")
elseif (FileName:sub(#FileName-3, #FileName) ~= ".txt") then
    Error:Error("FILE ERROR: FILE MUST BE A .TXT")
elseif (assert(io.open(FileName, "r")) == false) then
    Error:Error("FILE ERROR: CANNOT OPEN FILE " .. FileName)
end

local File = io.open(FileName, "r")
local Program = ""
local CurrentLine = File:read("*line")

while CurrentLine ~= nil do
    Program = Program .. "\n" .. CurrentLine
    CurrentLine = File:read("*line")
end

File:close()

Interpreter = CInterpreter:new(Program)
Interpreter:Execute()