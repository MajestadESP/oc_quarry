local GetFileContents = require('GetFileContents')
local FilePutContents = require('FilePutContents')
local ChunkData = require('ChunkData')
local ChunkDataCollection = require('ChunkDataCollection')
local ui = require('UI')
local split = require('split')
local serialization = require('serialization')
local term = require('term')
local event = require('event')
local fs = require('filesystem')
local component = require('component')
local gpu = component.gpu
local modem = component.modem
local running = true
term.clear()

local directory = '/home/quarryV2/'

do
    if not fs.exists(directory) then
        fs.makeDirectory(directory)
    end
end
-- ######## CONFIG ########

local port = 57812

-- ########################

local resolution = {gpu.getResolution()}
modem.open(port)

local anchorPosition = {}
local baseFace = nil

local colors = {
    canceled = 0xff0400,
    complete = 0x1dc902,
    queued = 0xff9e37,
    mining = 0xffcfba
}

-- returns the numbers x and y as a string seperated by a dash, truncating decimals. 4.5 and 2.3 -> 4-2
local function xyID(x,y)
    return split(tostring(x),'.')[1] .. '-' .. split(tostring(y),'.')[1]
end

-- create files that don't exist
do
    if not fs.exists(directory .. 'blocksMined.txt') then
        FilePutContents(directory .. 'blocksMined.txt', '0')
    end
    
    if not fs.exists(directory .. 'chunkInfo.txt') then
        FilePutContents(directory .. 'chunkInfo.txt', '{}')
    end
    
    if not fs.exists(directory .. 'robotRegistry.txt') then
        FilePutContents(directory .. 'robotRegistry.txt', '{}')
    end
end

-- get position of the waypoint if it isn't saved to the file
if not fs.exists(directory .. 'waypointPosition.txt') then
    local gotCoordinates = false

    -- create some UI to get input
    local collection = ui.collection.new()
    collection:add(ui.label.new(2,2,'Enter coordinates of waypoint'))
   
    local xInput = ui.textInput.new(4,4,10)
    local yInput = ui.textInput.new(4,6,10)
    local zInput = ui.textInput.new(4,8,10)
    local fInput = ui.textInput.new(4,10,10)
    
    collection:add(xInput)
    collection:add(yInput)
    collection:add(zInput)
    collection:add(fInput)
    
    collection:add(ui.label.new(2,4,'X'))
    collection:add(ui.label.new(2,6,'Y'))
    collection:add(ui.label.new(2,8,'Z'))
    collection:add(ui.label.new(2,10,'F'))
    
    do
        local enterButton = ui.button.new(2,12,'Enter')
        enterButton.onClick = function()
            local x = tonumber(xInput.text)
            local y = tonumber(yInput.text)
            local z = tonumber(zInput.text)
            local f = tonumber(fInput.text)
        
            gotCoordinates = z and y and z and f -- make sure that every input is a valid number
        end
        
        collection:add(enterButton)
    end
    
    collection:draw()
    -- pull events for the collection to handle until gotCoordinates is true
    while not gotCoordinates do
        local e = { event.pull() }
    
        collection:handleEvent(e)
    end
    
    -- set anchor positions
    anchorPosition.x = tonumber(xInput.text)
    anchorPosition.y = tonumber(yInput.text)
    anchorPosition.z = tonumber(zInput.text)
    anchorPosition.f = tonumber(fInput.text)
    term.clear()
    
    -- save it to a file
    FilePutContents(directory .. 'waypointPosition.txt', serialization.serialize(anchorPosition))
else
    anchorPosition = serialization.unserialize(GetFileContents(directory .. 'waypointPosition.txt'))
end

-- readonly, takes the position of the waypoint, divides it by 16 to get chunk coords
local anchorChunkPos = {
    x = math.floor(anchorPosition.x / 16),
    z = math.floor(anchorPosition.z / 16)
}

-- keeps track of the map offset
local mapCenterPosition = {
    x=anchorChunkPos.x,
    y=anchorChunkPos.z
}

local blocksMined = tonumber(GetFileContents(directory .. 'blocksMined.txt'))

-- create UI collection
local collection = ui.collection.new()
collection:add(ui.label.new(2,3,'The Blimp Quarry Service (V2)')) -- title

-- initialise chunk map
local chunkMap = ui.cellMap.new(2,10,30,20,anchorChunkPos.x-15,anchorChunkPos.z-10)
collection:add(chunkMap)

-- Stuff for pointing out the central chunk
chunkMap:set(anchorChunkPos.x, anchorChunkPos.z, 0x3503ff)
local centralId = xyID(anchorChunkPos.x, anchorChunkPos.z)

-- display chunk coordinates of chunk anchor is in
collection:add(ui.label.new(2,5,'        Central: ' .. tostring(anchorChunkPos.x) .. ', ' .. tostring(anchorChunkPos.z) .. '       '))
collection:add(ui.label.new(33,10,'Central',0x3503ff))

-- labels to counters
collection:add(ui.label.new(33,12,'Queued',colors.queued))
collection:add(ui.label.new(33,13,'Canceled',colors.canceled))
collection:add(ui.label.new(33,14,'Mining',colors.mining))
collection:add(ui.label.new(33,15,'Complete',colors.complete))

-- add counters to UI
local lblQueuedCounter = ui.label.new(42,12,'0')
local lblCanceledCounter = ui.label.new(42,13,'0')
local lblMiningCounter = ui.label.new(42,14,'0')
local lblCompleteCounter = ui.label.new(42,15,'0')

collection:add(lblQueuedCounter)
collection:add(lblCanceledCounter)
collection:add(lblMiningCounter)
collection:add(lblCompleteCounter)

local chunkCollection = ChunkDataCollection.new()
local robotRegistry = serialization.unserialize(GetFileContents(directory .. 'robotRegistry.txt'))

-- table for displaying robot status
local tblRobotStatus = ui.table.new(60, 12, 20, {
    {text="Robot",width=15},
    {text="Status",width=8},
    {text="Chunk ID",width=15}
})
collection:add(tblRobotStatus)

for id,val in pairs(robotRegistry) do
    tblRobotStatus:addRow(id, {val.name or id, val.state, val.chunkId or ""})
end

-- UI for setting registered robots names
do
    local txtNameInput = ui.textInput.new(69,8,20)

    local btnSetName = ui.button.new(60,8,'Set name')
    btnSetName.onClick = function()
        local row = tblRobotStatus:getSelected()
        row[1] = txtNameInput.text
        robotRegistry[row.id].name = txtNameInput.text
        tblRobotStatus:alterSelected(row)
    end
    
    collection:add(txtNameInput)
    collection:add(btnSetName)
end

-- UI for delete registered robots
--do
--    local btnDel = ui.button.new(60,10,'Delete')
--    btnDel.onClick = function()
--        local row = tblRobotStatus:getSelected()
--        
--        tblRobotStatus:alterSelected(row)
--    end
--    
--    collection:add(btnDel)
--end

function loadChunkFiles()
    -- all chunk data is stored within one file, store method could be changed to avoid expensive use of serialization which comes with a storage overhead
    local chunks = serialization.unserialize(GetFileContents(directory .. 'chunkInfo.txt'))

    -- for every chunk in the fille
    for i,chunk in pairs(chunks) do
        -- create an object for it
        local newChunk = ChunkData.new(chunk.x, chunk.z, chunk.state)
    
        -- add it to the collection
        chunkCollection:addChunk(newChunk, chunk.state == 'queued')
    
        -- update chunkMap
        if newChunk.state == 'queued' then
            chunkMap:set(newChunk.x, newChunk.z, colors.queued)
        elseif newChunk.state == 'mining' then
            chunkMap:set(newChunk.x, newChunk.z, colors.mining)
        elseif newChunk.state == 'complete' then
            chunkMap:set(newChunk.x, newChunk.z, colors.complete)
        elseif newChunk.state == 'canceled' then
            chunkMap:set(newChunk.x, newChunk.z, colors.canceled)
        else
            error('Failed loading, invalid chunk state: ' .. newChunk.state)
        end
    end

    -- initialize counters
    lblQueuedCounter.text = tostring(chunkCollection.stateCounters['queued'] or 0) .. '     '
    lblCanceledCounter.text = tostring(chunkCollection.stateCounters['canceled'] or 0) .. '     '
    lblMiningCounter.text = tostring(chunkCollection.stateCounters['mining'] or 0) .. '     '
    lblCompleteCounter.text = tostring(chunkCollection.stateCounters['complete'] or 0) .. '     '

    lblQueuedCounter:draw()
    lblCanceledCounter:draw()
    lblMiningCounter:draw()
    lblCompleteCounter:draw()
end

function saveChunkFiles()
    local chunkDataArray = {}

    for i,chunk in pairs(chunkCollection.chunks) do
        -- chunk:getSerializable returns an object identical to the chunk, but without the functions, allowing it to be serialized
        table.insert(chunkDataArray, chunk:getSerializable())
    end
    
    FilePutContents(directory .. 'chunkInfo.txt', serialization.serialize(chunkDataArray))
    FilePutContents(directory .. 'robotRegistry.txt', serialization.serialize(robotRegistry))
end

-- display current center position of map
local lblCurrentMapPos = ui.label.new(2,6,'Current Map Pos: ' .. tostring(anchorChunkPos.x) .. ', ' .. tostring(anchorChunkPos.z) .. '       ')
collection:add(lblCurrentMapPos)

-- display last clicked chunk
local lblLastChunkClicked = ui.label.new(33,19,'')
collection:add(lblLastChunkClicked)

-- display total blocks mined
collection:add(ui.label.new(33,17,'Blocks Mined:'))
local blocksMinedLabel = ui.label.new(47, 17, tostring(blocksMined))
collection:add(blocksMinedLabel)

-- exit button
do
    local button = ui.button.new(1,1,'Exit')
    button.onClick = function(this)
        running = false
        saveChunkFiles()
    end
    
    collection:add(button)
end

-- directional navigation buttons
do -- up
    local button = ui.button.new(4,32,'/\\')
    button.onClick = function(this)
        chunkMap:offset(0,-1)
        mapCenterPosition.y = mapCenterPosition.y - 1
        lblCurrentMapPos.text = 'Current Map Pos: ' .. tostring(mapCenterPosition.x) .. ', ' .. tostring(mapCenterPosition.y) .. '       '
        lblCurrentMapPos:draw()
    end
    
    collection:add(button)
end
do -- down
    local button = ui.button.new(4,34,'\\/')
    button.onClick = function(this)
        chunkMap:offset(0,1)
        mapCenterPosition.y = mapCenterPosition.y + 1
        lblCurrentMapPos.text = 'Current Map Pos: ' .. tostring(mapCenterPosition.x) .. ', ' .. tostring(mapCenterPosition.y) .. '       '
        lblCurrentMapPos:draw()
    end
    
    collection:add(button)
end
do -- right
    local button = ui.button.new(6,33,'>')
    button.onClick = function(this)
        chunkMap:offset(1,0)
        mapCenterPosition.x = mapCenterPosition.x + 1
        lblCurrentMapPos.text = 'Current Map Pos: ' .. tostring(mapCenterPosition.x) .. ', ' .. tostring(mapCenterPosition.y) .. '       '
        lblCurrentMapPos:draw()
    end
    
    collection:add(button)
end
do -- left
    local button = ui.button.new(3,33,'<')
    button.onClick = function(this)
        chunkMap:offset(-1,0)
        mapCenterPosition.x = mapCenterPosition.x - 1
        lblCurrentMapPos.text = 'Current Map Pos: ' .. tostring(mapCenterPosition.x) .. ', ' .. tostring(mapCenterPosition.y) .. '     '
        lblCurrentMapPos:draw()
    end 
    
    collection:add(button)
end

chunkMap.onClick = function(this, tileX, tileY, realX, realY, button)
    -- tasks to do when updating
        -- set colour of cell on map
        -- set chunk states
        -- save state to file
            -- new format is array of chunk data objects, which will be processed on load
        -- update counters

    local id = xyID(tileX, tileY)
    local chunk = chunkCollection:getChunk(id)

    if id == centralId then return nil end

    lblLastChunkClicked.text = tostring(tileX) .. ', ' .. tostring(tileY)
    lblLastChunkClicked:draw()

    if button == 0 then -- left click
        if not chunk then -- queue chunk if chunk doesn't exist yet
            chunk = ChunkData.new(tileX, tileY, 'queued')
            chunkCollection:addChunk(chunk, true)
            chunkMap:set(tileX, tileY, colors.queued)
        elseif chunk.state == 'queued' or chunk.state == 'canceled' or chunk.state == 'complete' then -- remove it if complete, canceled, or queued
            chunkCollection:removeChunk(id)
            chunk = nil
            chunkMap:reset(tileX, tileY)
        elseif chunk.state == 'mining' then -- if a robot has picked up this chunk, cancel it so the robot knows when it returns
            chunkCollection:changeState(id, 'canceled')
            chunkMap:set(tileX, tileY, colors.canceled)
        end
    end
    
    lblQueuedCounter:update(tostring(chunkCollection.stateCounters['queued'] or 0) .. '     ')
    lblCanceledCounter:update(tostring(chunkCollection.stateCounters['canceled'] or 0) .. '     ')
    lblMiningCounter:update(tostring(chunkCollection.stateCounters['mining'] or 0) .. '     ')
    lblCompleteCounter:update(tostring(chunkCollection.stateCounters['complete'] or 0) .. '     ')

    this:drawCell(tileX, tileY, realX, realY)
    saveChunkFiles() -- feeling this might be too long to execute on each change, incorporate save button?
end

loadChunkFiles()
collection:draw()

while running do
    local e = { event.pull() }
    
    if e[1] == 'modem_message' then
        local remote = e[3]
        local header = e[6]
        local data = e[7]
        
        if header == 'PING' then
            modem.send(remote, port, 'PING')
            
        elseif header == 'GET_ANCHOR' then
            modem.send(remote, port, 'ANCHOR', serialization.serialize(anchorPosition))
            
        elseif header == 'GET_NEW_CHUNK' then
            if robotRegistry[remote] == nil then
                robotRegistry[remote] = {
                    state = 'idle',
                    chunkId = nil
                }
                
                tblRobotStatus:addRow(remote, {remote, 'idle', ''})
            end
            
            ::miningReset::
            if robotRegistry[remote].state == 'idle' then
                local chunk = chunkCollection:dequeue()
                
                if chunk ~= nil then
                    local chunkId = chunk:getId()
                    
                    chunkCollection:changeState(chunkId, 'mining')
                    
                    local coords = {
                        x = chunk.x,
                        z = chunk.z
                    } 
                    
                    modem.send(remote, port, 'NEW_CHUNK', serialization.serialize(coords))
                    
                    robotRegistry[remote].chunkId = chunkId
                    robotRegistry[remote].state = 'mining'
                    tblRobotStatus:alterRow(remote, {robotRegistry[remote].name or remote, robotRegistry[remote].state, robotRegistry[remote].chunkId or ""})
                    
                    lblQueuedCounter:update(tostring(chunkCollection.stateCounters['queued']) .. '     ')
                    lblMiningCounter:update(tostring(chunkCollection.stateCounters['mining']) .. '     ')
                    
                    chunkMap:set(chunk.x, chunk.z, colors.mining)
                    chunkMap:draw()
                else
                    modem.send(remote, port, 'NO_CHUNK')
                end
            elseif robotRegistry[remote].state == 'mining' then
                local chunk = chunkCollection:getChunk(robotRegistry[remote].chunkId)
                
                if chunk == nil then
                    robotRegistry[remote].state = 'idle'
                    tblRobotStatus:alterRow(remote, {robotRegistry[remote].name or remote, robotRegistry[remote].state, ''})
                    goto miningReset
                end
                
                local coords = {
                    x = chunk.x,
                    z = chunk.z
                }
                modem.send(remote, port, 'NEW_CHUNK', serialization.serialize(coords))
            end
            
        elseif header == 'UPDATE' then
            if not data then
                error("Data must be a serialized table including the count of blocks mined for UPDATE messages")
            end
        
            local data = serialization.unserialize(data)
            local count = data.count
            
            blocksMined = blocksMined + count
            FilePutContents(directory .. 'blocksMined.txt', tostring(blocksMined))
            blocksMinedLabel:update(tostring(blocksMined))
            
            local chunk = chunkCollection:getChunk(robotRegistry[remote].chunkId)
            
            if chunk == nil or chunk.state == 'canceled' or chunk.state == 'complete' then
                modem.send(remote, port, 'CANCEL')
                robotRegistry[remote].state = 'idle'
                tblRobotStatus:alterRow(remote, {robotRegistry[remote].name or remote, robotRegistry[remote].state, ''})
            else
                modem.send(remote, port, 'CONTINUE')
            end
            
        elseif header == 'COMPLETE_CHUNK' then -- data.coords is the x and z of the chunk coordinates
            local data = serialization.unserialize(data)
            local count = data.count
            
            local chunkId = robotRegistry[remote].chunkId
            local chunk = chunkCollection:getChunk(chunkId)
            
            if chunk.state ~= 'complete' then
                blocksMined = blocksMined + count
                FilePutContents(directory .. 'blocksMined.txt', tostring(blocksMined))
                blocksMinedLabel:update(tostring(blocksMined))
            end
            
            chunkCollection:changeState(chunkId, 'complete')

            lblMiningCounter:update(tostring(chunkCollection.stateCounters['mining']) .. '     ')
            lblCompleteCounter:update(tostring(chunkCollection.stateCounters['complete']) .. '     ')
            
            robotRegistry[remote].state = 'idle'
            tblRobotStatus:alterRow(remote, {robotRegistry[remote].name or remote, robotRegistry[remote].state, ''})
            
            chunkMap:set(chunk.x, chunk.z, colors.complete)
            chunkMap:draw()
            
        elseif header == 'CANCEL_CHUNK' then -- recieved when robot cancels the mining of a chunk, returns reason as data
            local data = serialization.unserialize(data)
            local reason = data.reason
            local count = data.count
            
            blocksMined = blocksMined + count
            FilePutContents(directory .. 'blocksMined.txt', tostring(blocksMined))
            blocksMinedLabel:update(tostring(blocksMined))
            
            local chunkId = robotRegistry[remote].chunkId
            local chunk = chunkCollection:getChunk(chunkId)
            chunkCollection:changeState(chunkId, 'canceled')

            robotRegistry[remote].state = 'idle'
            tblRobotStatus:alterRow(remote, {robotRegistry[remote].name or remote, robotRegistry[remote].state, ''})

            chunkMap:set(chunk.x, chunk.z, colors.canceled)
            chunkMap:draw()
            
        end
    end

    collection:handleEvent(e)
end

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
term.clear()













