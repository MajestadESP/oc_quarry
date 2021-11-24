local Position

Position = {
    __add = function(lhs, rhs)
        local r = Position.new(0, 0, 0)
    
        r.x = lhs.x + rhs.x
        r.y = lhs.y + rhs.y
        r.z = lhs.z + rhs.z
        
        return r
    end,
    
    __sub = function(lhs, rhs)
        local r = Position.new(0, 0, 0)
    
        r.x = lhs.x - rhs.x
        r.y = lhs.y - rhs.y
        r.z = lhs.z - rhs.z
        
        return r
    end,
}

Position.new = function(x,y,z)
    local this = setmetatable({}, Position)
    
    this.x = x
    this.y = y
    this.z = z
    
    this.magnitude = function(this)
        local xs = this.x * this.x
        local ys = this.y * this.y
        local zs = this.z * this.z
        
        return math.sqrt(xs + ys + zs)
    end
    
    this.manhattanMagnitude = function(this)
        return this.x + this.y + this.z
    end
    
    return this
end

return Position