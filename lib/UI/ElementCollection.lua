local ElementCollection = {}

ElementCollection.new = function()
    local this = setmetatable({},ElementCollection)
    
    this.elements = {}
    
    this.add = function(this, element)
        if element.handleEvent then
            table.insert(this.elements, element)
        else
            error('Tried to add element with no event handler function, all elements must have a callable "handleEvent"')
        end
    end
    
    this.handleEvent = function(this, event)
        for i = 1,#this.elements,1 do
            this.elements[i]:handleEvent(event)
        end
    end
    
    this.draw = function(this)
        for i = 1,#this.elements,1 do
            if this.elements[i].draw then
                this.elements[i]:draw()
            end
        end
    end
    
    return this
end

return ElementCollection