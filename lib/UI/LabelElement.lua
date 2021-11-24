local gpu = require('component').gpu

local LabelElement = {}

LabelElement.new = function(x,y,label,backgroundColor)
    local this = setmetatable({},TextInputElement)
    
    this.backgroundColor = backgroundColor or 0x555555
    this.foregroundColor = 0xFFFFFF
    this.text = label
    this.centerLabel = false
    this.x = x
    this.y = y
    this.width = #this.text
    
    this.draw = function(this)
        gpu.setBackground(this.backgroundColor)
        gpu.setForeground(this.foregroundColor)
        
        gpu.fill(this.x, this.y, this.width, 1, ' ')
        
        if this.centerLabel then
            local halfLengthOfText = #this.text // 2
            local centerOfButton = this.x + this.width // 2
            
            gpu.set(centerOfButton - halfLengthOfText, this.y, this.text)
        else
            gpu.set(this.x, this.y, this.text)
        end
        
        gpu.setBackground(0x000000)
        gpu.setForeground(0xFFFFFF)
    end
    
    this.update = function(this, text)
        this.text = text
        this:draw()
    end
    
    this.handleEvent = function(this, event) end
    
    return this
end

return LabelElement