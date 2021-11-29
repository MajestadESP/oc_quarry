local ChunkData = {}
local split = require('split')

ChunkData.new = function(x,z,state)
    local this = setmetatable({},ChunkData)
    
    this.x = x
    this.z = z
    this.state = state
    
    this.getId = function(this)
        return split(tostring(this.x),'.')[1] .. '-' .. split(tostring(this.z),'.')[1]
    end
    
    this.getSouthWestCorner = function(this)        
        return {
            x = math.floor(this.x * 16),
            z = math.floor((this.z * 16) + 15)
        }
    end
    
    this.getSerializable = function(this)
        return {
            x = this.x,
            z = this.z,
            state = this.state
        }
    end
    
    return this
end

return ChunkData