local ChunkData = require('ChunkData')
local ChunkDataCollection = {}

ChunkDataCollection.new = function()
    local this = setmetatable({},ChunkDataCollection)
    
    this.arrayCounter = 1
    
    this.chunks = {}
    this.idIndexDictionary = {}
    this.queue = {}
    this.stateCounters = {}
    
    this.deltaStateCounter = function(this, state, delta)
        if this.stateCounters[state] == nil then
            this.stateCounters[state] = 0
        end
    
        this.stateCounters[state] = this.stateCounters[state] + delta
    end
    
    this.changeState = function(this, id, state)
        local chunk = this:getChunk(id)
        if not chunk then return nil end
        
        this:deltaStateCounter(chunk.state, -1)
        this:deltaStateCounter(state, 1)
        chunk.state = state
    end
    
    this.addChunk = function(this, chunk, enqueue)
        enqueue = enqueue or false
        
        local id = chunk:getId()

        -- insert chunk into array at specific index
        -- add entry to dictionary
        -- increment counter
        this.chunks[this.arrayCounter] = chunk
        this.idIndexDictionary[id] = this.arrayCounter
        this.arrayCounter = this.arrayCounter + 1
        
        -- increment state counter based on chunk state
        this:deltaStateCounter(chunk.state, 1)
        
        -- if enqueue, add to queue
        if enqueue then
            table.insert(this.queue, id)
        end
    end
    
    this.removeChunk = function(this, id)
        -- get info
        local index = this.idIndexDictionary[id]
        if not index then return nil end
        
        local chunk = this.chunks[index]
        if not chunk then return nil end
        
        this.chunks[index] = nil
        
        this.idIndexDictionary[id] = nil
        this:deltaStateCounter(chunk.state, -1)
        
        return chunk
    end
    
    this.dequeue = function(this)
        -- return the oldest valid entry in the queue
        local index = nil
        
        repeat
            local id = table.remove(this.queue, 1)
            index = this.idIndexDictionary[id]
        until index ~= nil or #this.queue == 0

        if not index then return nil end
        
        return this.chunks[index]
    end
    
    this.enqueue = function(this, id)
        table.insert(this.queue, id)
    end
    
    this.getChunk = function(this, id)
        local index = this.idIndexDictionary[id]
        if not index then return nil end
    
        return this.chunks[index]
    end
    
    return this
end

return ChunkDataCollection