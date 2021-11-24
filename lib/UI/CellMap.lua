local gpu = require('component').gpu
local CheckBounds = require('CheckBounds')

local beep = function(frequency) end
if require('component').isAvailable('beep') then
    local beepCard = require('component').beep
    beep = function(frequency)
        beepCard.beep({[frequency]=.1})
    end
end


local CellMap = {}

CellMap.new = function(x,y,width,height,offsetX,offsetY)
    local this = setmetatable({}, CellMap)
    
    this.x = x
    this.y = y
    this.width = width
    this.height = height
    this.offsetX = offsetX
    this.offsetY = offsetY
    this.defaultColor = 0x333333
    
    this.cells = {}
    
    this.onClick = function(this,cellX,cellY)
        this:highlight(cellX, cellY, 0xFFFFFF)
        this:draw()
    end
    
    this.set = function(this,x,y,_color,_state)
        if not this.cells[x] then
            this.cells[x] = {}
        end
        
        this.cells[x][y] = {color=_color,state=_state}
    end
    
    this.reset = function(this,x,y)
        if not this.cells[x] then
            return nil
        end
        
        this.cells[x][y] = nil
    end
    
    this.resetAll = function(this)
        this.cells = {}
    end
    
    this.getState = function(this,x,y)
        if not this.cells[x] then return nil end
        if not this.cells[x][y] then return nil end
    
        return this.cells[x][y].state
    end
    
    this.offset = function(this,dx,dy)
        this.offsetX = this.offsetX + dx
        this.offsetY = this.offsetY + dy
        
        this:draw()
    end
    
    this.drawCell = function(this,cellX,cellY,realX,realY)
        local color = this.defaultColor
        if this.cells[cellX] then 
            if this.cells[cellX][cellY] then
                color = this.cells[cellX][cellY].color
            end
        end
       
        gpu.setBackground(color)
        gpu.set(realX,realY,' ')
    end
    
    this.draw = function(this) 
        -- TODO draw onto screen and copy whole grid over, maybe faster?
    
        for w = 1,this.width,1 do
            for h = 1,this.height,1 do
                local color = this.defaultColor
                if this.cells[w+this.offsetX] then
                    if this.cells[w+this.offsetX][h+this.offsetY] then
                        color = this.cells[w+this.offsetX][h+this.offsetY].color
                    end
                end
                
                gpu.setBackground(color)
                gpu.set(this.x+w-1,this.y+h-1,' ')
            end
        end
    end
    
    this.handleEvent = function(this,e)
        if e[1] == 'touch' and CheckBounds(this.x, this.y, this.x + this.width - 1, this.y + this.height - 1, e[3], e[4]) then
            local cellX = e[3] - this.x + this.offsetX + 1
            local cellY = e[4] - this.y + this.offsetY + 1
        
            beep(1200)
            this:onClick(cellX,cellY,e[3],e[4],e[5])
        end
    end
    
    return this
end

return CellMap