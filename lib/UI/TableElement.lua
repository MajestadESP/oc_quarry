local CheckBounds = require('CheckBounds')
local TableElement = {}
local gpu = require('component').gpu

local beep = function(frequency) end
if require('component').isAvailable('beep') then
    local beepCard = require('component').beep
    beep = function(frequency)
        beepCard.beep({[frequency]=.1})
    end
end

-- columns is an array containing object literals with text and width, if width isn't defined length of text is used
TableElement.new = function(x,y,height,columns)
    local this = setmetatable({}, TableElement)
    
    this.x = x
    this.y = y
    this.height = height
    this.columns = columns
    this.columnCount = #this.columns
    this.rows = {}
    this.width = 1
    this.ids = {} -- contains indexes by ID
    this.selected = 1
    
    for c = 1,#this.columns,1 do
        if not this.columns[c].width then
            this.columns[c].width = #this.columns[c].text + 2
        end
        
        this.width = this.width + this.columns[c].width
    end
    
    this.colours = {
        columnA = 0x444444,
        columnB = 0x888888,
        headersA = 0x449999,
        headersB = 0x004444,
        text = 0xFFFFFF
    }
    
    this.addRow = function(this, id, row)
        if #row < this.columnCount then
            error("Number of rows must be equal to TableElement.columnCount")
        end
        
        row.id = id
        
        table.insert(this.rows, row)
        this.ids[id] = #this.rows
        this:drawRow(#this.rows)
        return #this.rows
    end
    
    this.alterRow = function(this, id, row)
        if #row < this.columnCount then
            error("Number of rows must be equal to TableElement.columnCount")
        end
        
        local index = this.ids[id]
    
        row.id = id
        this.rows[index] = row
        this:drawRow(index)
    end
    
    this.alterSelected = function(this, row)
        this.rows[this.selected] = row
        this:drawRow(this.selected)
    end
    
    this.getSelected = function(this)
        return this.rows[this.selected]
    end
    
    this.removeRow = function(this, id)
        local index = this.ids[id]
        
        table.remove(this.rows, index)
        this:drawRow(index)
    end
    
    this.draw = function(this)
        local deltaX = 0
        
        gpu.setForeground(this.colours.text)
        gpu.setBackground(0x111111)
        gpu.fill(this.x, this.y, this.width, this.height, ' ')
        
        for c = 1,#this.columns,1 do
            if c % 2 == 0 then
                gpu.setBackground(this.colours.headersA)
            else
                gpu.setBackground(this.colours.headersB)
            end
            
            gpu.fill(this.x + deltaX + 1, this.y, this.columns[c].width, 1, ' ')
            gpu.set(this.x + deltaX + 1, this.y, this.columns[c].text)
            deltaX = deltaX + this.columns[c].width
        end
        
        this:drawRows()
    end
    
    this.select = function(this, newSelection)
        gpu.setBackground(0x111111)
        gpu.set(this.x, this.y + this.selected, ' ')
        gpu.setBackground(0xFF0000)
        gpu.set(this.x, this.y + newSelection, ' ')
        
        this.selected = newSelection
    end
    
    this.drawRow = function(this, index)
        if this.rows[index] == nil then
            gpu.setBackground(0x111111)
            gpu.fill(this.x + deltaX, this.y + index, this.width, 1, ' ')
        else
            local deltaX = 0
            
            for c = 1,#this.columns,1 do
                if c % 2 == 0 then
                    gpu.setBackground(this.colours.columnB)
                else
                    gpu.setBackground(this.colours.columnA)
                end
                
                gpu.fill(this.x + deltaX + 1, this.y + index, this.columns[c].width, 1, ' ') -- fill in table cell
                gpu.set(this.x + deltaX + 1, this.y + index, string.sub(this.rows[index][c],1,this.columns[c].width - 1)) -- write text to cell
                deltaX = deltaX + this.columns[c].width
            end
        end
    end
    
    this.drawRows = function(this)
        gpu.setForeground(this.colours.text)
    
        for r = 1,#this.rows,1 do
            if r > this.height then
                return nil
            end
            
            this:drawRow(r)
        end
    end
    
    this.handleEvent = function(this, event)
        if event[1] == 'touch' then
            local x = event[3]
            local y = event[4]
            
            if CheckBounds(this.x, this.y, this.x + this.width - 1, this.y + this.height, x, y) then
                beep(600)
                
                local newSelection = y - this.y
                
                if this.rows[newSelection] then
                    this:select(newSelection)
                end
            end
        end
    end
    
    return this
end

return TableElement