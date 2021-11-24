local gpu = require('component').gpu
local CheckBounds = require('CheckBounds')

local beep = function(frequency) end
if require('component').isAvailable('beep') then
    local beepCard = require('component').beep
    beep = function(frequency)
        beepCard.beep({[frequency]=.1})
    end
end

local ButtonElement = {}

ButtonElement.new = function(x,y,label)
    local this = setmetatable({},TextInputElement)
    
    this.backgroundColor = 0xAAAAAA
    this.foregroundColor = 0x000000
    this.labelText = label
    this.centerLabel = false
    this.x = x
    this.y = y
    this.width = #this.labelText
    
    this.draw = function(this)
        gpu.setBackground(this.backgroundColor)
        gpu.setForeground(this.foregroundColor)
        
        gpu.fill(this.x, this.y, this.width, 1, ' ')
        
        if this.centerLabel then
            local halfLengthOfText = #this.labelText / 2
            local centerOfButton = this.x + this.width / 2
            
            gpu.set(centerOfButton - halfLengthOfText, this.y, this.labelText)
        else
            gpu.set(this.x, this.y, this.labelText)
        end
        
        gpu.setBackground(0x000000)
        gpu.setForeground(0xFFFFFF)
    end
    
    this.onClick = function(this)
        
    end
    
    this.handleEvent = function(this, event)
        if event[1] == 'touch' then
            local x = event[3]
            local y = event[4]
            
            if CheckBounds(this.x, this.y, this.x + this.width - 1, this.y, x, y) then
                beep(600)
                this:onClick()
            end
        end
    end
    
    return this
end

return ButtonElement