Error = {}

function Error:Error(str)
    print(str)
    os.exit()
end

return Error