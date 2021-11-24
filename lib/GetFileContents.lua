return function(filePath)
    local file = io.open(filePath)
    
    if not file then return false end
    
    local text = file:read("*a")
    file:close()
    
    return text
end