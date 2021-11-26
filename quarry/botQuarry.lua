-- to install on robot
-- 1. copy Position to home
-- 2. copy this file to home


local rb = require('robot')
local component = require('component')
local navigation = component.navigation
local serialization = require("serialization")
local Pos = require('Position')
local event = require('event')
local os = require('os')
local computer = require('computer')
local math = require('math')

-- ######## CONFIG ########

local port = 57812
local depth = 2

-- ########################

local modem = component.modem
modem.open(port)

local stopCurrentChunk = false

local function fetch(port, header, data, address, awaitHeader)
    if address then
        modem.send(address, port, header, data)
    else
        modem.broadcast(port, header, data)
    end
    
    local timeouts = 0
    
    local ev = nil
    repeat
        ev = { event.pull(3,'modem_message') }
       
        if ev[1] == nil then timeouts = timeouts + 1 end
    until awaitHeader == nil or ev[6] == awaitHeader or timeouts >= 3
    
    if ev[1] == nil then 
        return {
            remote = nil,
            header = nil,
            data = nil,
        }
    end
    
    return {
        remote = ev[3],
        header = ev[6],
        data = ev[7]
    }
end

local function clonePosition(pos)
    return Pos.new(pos.x, pos.y, pos.z)
end

local serverAddress = nil
repeat
    local d = fetch(port, 'PING', nil, nil, 'PING')

    serverAddress = d.remote
    
    if d.header ~= 'PING' then print('Couldn\'t reach server, retrying...') end
until d.header == 'PING'

-- ## GET CURRENT POSITION ## --

local curPos = nil
local facing = nil
local anchorPosition = nil
do
    repeat
        local d = fetch(port, 'GET_ANCHOR', nil, serverAddress, 'ANCHOR')
        anchorPosition = serialization.unserialize(d.data)
    until d.header == 'ANCHOR' 

    local waypoints = navigation.findWaypoints(20)
    local positionRelativeToWaypoint = waypoints[1].position
    
    curPos = Pos.new(anchorPosition.x - positionRelativeToWaypoint[1], anchorPosition.y - positionRelativeToWaypoint[2], anchorPosition.z - positionRelativeToWaypoint[3])
    facing = anchorPosition.f
end

print('Got current position: ' .. tostring(curPos.x) .. ', ' .. tostring(curPos.y) .. ', ' .. tostring(curPos.z))
print('Facing: ' .. tostring(facing))
local homePos = clonePosition(curPos)

-- ########################## --

local blockCount = 0

local function swingUp()
    if rb.swingUp() then blockCount = blockCount + 1 end
end

local function swing()
    if rb.swing() then blockCount = blockCount + 1 end
end

local function swingDown()
    if rb.swingDown() then blockCount = blockCount + 1 end
end

local function forward(swingOnFail)
    repeat     
        local success, reason = rb.forward()
        
        if swingOnFail and not success then swing() end
    until success
    
    if facing == 0 then
        curPos.z = curPos.z - 1
    elseif facing == 1 then
        curPos.x = curPos.x + 1
    elseif facing == 2 then
        curPos.z = curPos.z + 1
    elseif facing == 3 then
        curPos.x = curPos.x - 1
    end
end

local function back()
    repeat 
        local success, reason = rb.back()
    until success
    
    if facing == 0 then
        curPos.x = curPos.x - 1
    elseif facing == 1 then
        curPos.z = curPos.z - 1
    elseif facing == 2 then
        curPos.x = curPos.x + 1
    elseif facing == 3 then
        curPos.z = curPos.z + 1
    end
end

local function up()
    repeat 
        local success, reason = rb.up()
    until success
    
    curPos.y = curPos.y + 1
end

local function down()
    repeat 
        local success, reason = rb.down()
    until success

    curPos.y = curPos.y - 1
end

local function turnLeft()
    rb.turnLeft()
    
    facing = facing - 1
    if facing < 0 then facing = 3 end
end

local function turnRight()
    rb.turnRight()
    
    facing = facing + 1
    if facing > 3 then facing = 0 end
end

local function turnTo(toFace)
    if facing == toFace then return nil end

    local tempFace = facing - 1
    if tempFace < 0 then tempFace = 3 end
    
    if tempFace == toFace then
        turnLeft()
    else
        turnRight()
    end
    
    if facing ~= toFace then turnRight() end
end

local function moveTo(pos,newFace)
    local function xz()
        local function x()
            if pos.x ~= curPos.x then
                if pos.x > curPos.x then
                    turnTo(1)
                else
                    turnTo(3)
                end
                repeat
                    forward()
                until curPos.x == pos.x
            end
        end
        
        local function z()
            if pos.z ~= curPos.z then
                if pos.z > curPos.z then
                    turnTo(2)
                else
                    turnTo(0)
                end
                repeat
                    forward()
                until curPos.z == pos.z
            end
        end
        
        if facing == 0 or facing == 2 then x() z()
        else z() x() end
    end
    
    if pos.y ~= curPos.y then
        local lastY = curPos.y
        
        if pos.y < lastY then xz() end
        
        repeat
            if pos.y < curPos.y then
                down()
            else
                up()
            end
        until pos.y == curPos.y
        
        if pos.y >= lastY then xz() end
    else xz() end
    
    if newFace then turnTo(newFace) end
end

local function getNewChunk()
    local newChunk = nil
    repeat
        print('Sent: GET_NEW_CHUNK')
        
        modem.send(serverAddress, port, 'GET_NEW_CHUNK')
        local e = { event.pull(3,'modem_message') }
        local header = e[6]
        local data = e[7]

        if data then
            newChunk = serialization.unserialize(data)
        end
        
        print('Recieved: ' .. (header or "nil"))
        
        if header ~= 'NEW_CHUNK' then
            os.sleep(10)
        end
    until header == 'NEW_CHUNK'
    
    print('Recieved New Chunk: ' .. serialization.serialize(newChunk))
    return newChunk
end

local function checkAndReturn(goBackToWork, travelHeight)
    if rb.count(rb.inventorySize()) > 0 or computer.energy() < computer.maxEnergy() * 0.2 then
        local workPosition = clonePosition(curPos)
        local workFace = facing
        
        local workPos = clonePosition(curPos)

        swingUp()
        moveTo(Pos.new(curPos.x, travelHeight, curPos.z))
        moveTo(Pos.new(homePos.x, travelHeight, homePos.z))
        moveTo(homePos)
        turnTo(anchorPosition.f)
        turnLeft()
        turnLeft()
        
        for i = 1,rb.inventorySize(),1 do
            rb.select(i)
            rb.drop()
        end
        
        rb.select(1)
        
        repeat
            os.sleep(1)
        until computer.energy() > computer.maxEnergy() * 0.9
        
        local d = fetch(port, 'UPDATE', serialization.serialize({count=blockCount}), serverAddress)
        blockCount = 0
        
        if d.header == 'CANCEL' then
            stopCurrentChunk = true
        elseif goBackToWork then
            moveTo(Pos.new(curPos.x, travelHeight, curPos.z))
            moveTo(Pos.new(workPosition.x, travelHeight, workPosition.z))
            moveTo(workPosition)
            turnTo(workFace)
        end
    end
end

local function xor(lhs, rhs) 
    return (not ((lhs and rhs) and (lhs or rhs))) and (lhs or rhs) -- what the fuck
end

while true do
    repeat
        os.sleep(1)
    until computer.energy() > computer.maxEnergy() * 0.9
    
    local travelHeight = math.random(100, 130)
    
    local chunk = getNewChunk() -- chunk.x, chunk.z
    local chunkCoords = {x=chunk.x, z=chunk.z}
    chunk.x = chunk.x * 16 + 1 -- convert coordinates from chunk to block
    chunk.z = (chunk.z+1) * 16 - 1
    
    print('Start position: ' .. serialization.serialize(chunk))
    
    moveTo(Pos.new(curPos.x, travelHeight, curPos.z))
    moveTo(Pos.new(chunk.x, travelHeight, chunk.z))
    repeat
        down()
        local detected, reason = rb.detectDown()
    until detected and reason == 'solid'
    
    turnTo(0)
    
    local reverseX = true
    blockCount = 0
    
    repeat
        swingDown()
        down()
        swingDown()
        down()
        reverseX = not reverseX
        
        for x = 0,15,1 do
            for z = 1,15,1 do
                swingUp()
                swingDown()
                swing()
                forward(true)
                checkAndReturn(true, travelHeight)
                if stopCurrentChunk then
                    stopCurrentChunk = false
                    goto skipChunk
                end
            end
            
            if x < 15 then            
                if xor(x % 2 == 0, reverseX)  then
                    turnRight()
                    swingUp()
                    swingDown()
                    swing()
                    forward(true)
                    turnRight()
                else
                    turnLeft()
                    swingUp()
                    swingDown()
                    swing()
                    forward(true)
                    turnLeft()
                end
            end
        end
        
        swingUp()
        turnLeft()
        turnLeft()
        swingDown()
        down()
    until curPos.y <= depth

    moveTo(Pos.new(curPos.x, travelHeight, curPos.z))
    moveTo(Pos.new(homePos.x, travelHeight, homePos.z))
    moveTo(homePos)
    turnTo(anchorPosition.f)
    turnLeft()
    turnLeft()
    
    ::skipChunk::
    
    for i = 1,rb.inventorySize(),1 do
        rb.select(i)
        rb.drop()
    end
    
    rb.select(1)
    
    turnLeft()
    turnLeft()
    
    modem.send(serverAddress, port, 'COMPLETE_CHUNK', serialization.serialize({count=blockCount}))
end