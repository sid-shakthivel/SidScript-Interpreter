test = {1, 2, 3}
best = {4, 5, 6}

NewTable = {}

for i = 1, #test do
    NewTable[i] = test[i]
end

for i = 1, #best do
   NewTable[#test+i] = best[i]
end

for i = 1, #NewTable do
    print(NewTable[i])
end