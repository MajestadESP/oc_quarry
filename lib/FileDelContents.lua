return function(filePath, content)
    local file = io.open(filePath, 'w')
    file:write(content)
    file:close()
end