test = {1, 2, 3}
best = {4, 5, 6}

NewTable = { table.unpack(test), table.unpack(best) }
print(#NewTable)