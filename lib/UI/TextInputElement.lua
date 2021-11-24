local gpu = require('component').gpu
local CheckBounds = require('CheckBounds')
local acceptableKeys = require('AcceptableInput')
local keyboard = require('keyboard')
local keys = keyboard.keys

keys[12] = '-'

local TextInputElement = {}

TextInputElement.new = function(x,y,width)
    local this = setmetatable({},TextInputElement)
    
    this.active = false
    this.activeBackgroundColor = 0x444444
    this.inactiveBackgroundColor = 0x333333
    this.foregroundColor = 0xFFFFFF
    
    this.x = x
    this.y = y
    this.width = width
    
    this.text = ''
    
    this.onEnter = function(this)
        this.active = false
        this:draw()
    end
    
    this.onBack = function(this)
        if #this.text > 0 then
            this.text = string.sub(this.text, 1, #this.text - 1)
            this:draw()
        end
    end
    
    this.draw = function(this)
        gpu.setForeground(this.foregroundColor)
        
        if this.active then
            gpu.setBackground(this.activeBackgroundColor)
        else
            gpu.setBackground(this.inactiveBackgroundColor)
        end
        
        gpu.fill(this.x, this.y, this.width, 1, ' ')
        gpu.set(this.x, this.y, this.text)
        
        gpu.setForeground(0xFFFFFF)
        gpu.setBackground(0x000000)
    end
    
    this.handleEvent = function(this, event)
        if event[1] == 'key_down' and this.active then
            local keyCode = event[4]
            
            if keyCode == 28 then -- enter
                this:onEnter()
            elseif keyCode == 14 then -- back
                this:onBack()
            elseif keyCode == 57 and #this.text + 1 <= this.width then -- space
                this.text = this.text .. ' '
                this:draw()
            else
                local key = keys[keyCode]
                if acceptableKeys[string.lower(key)] and #this.text + 1 <= this.width then
                    if keyboard.isShiftDown() then
                        key = string.upper(key)
                    end
                
                    this.text = this.text .. key
                    this:draw()
                end
            end
            
        elseif event[1] == 'touch' then
            local x = event[3]
            local y = event[4]
            
            if CheckBounds(this.x, this.y, this.x + this.width - 1, this.y, x, y) then
                this.active = true
                this:draw()
            else
                this.active = false
                this:draw()
            end
        end
    end
    
    return this
end

return TextInputElement